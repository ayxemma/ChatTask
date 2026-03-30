import Foundation
import SwiftData

enum ChatMessageRole: String, Equatable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: ChatMessageRole
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), role: ChatMessageRole, text: String, timestamp: Date = .now) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}

enum VoiceFlowState: Equatable {
    case idle
    case listening
    case processing
    case success
    case error
}

@MainActor
@Observable
final class VoiceCommandViewModel {
    var chatMessages: [ChatMessage] = []
    var chatFlowState: VoiceFlowState = .idle
    var chatDraftText: String = ""
    var parsedCommand: ParsedCommand?

    /// Backing store for UI/speech locale (synced from `@AppStorage` via owning views).
    var chatSpeechInputLanguage: AppUILanguage = .defaultForDevice()

    /// Same as `chatSpeechInputLanguage` (legacy name for speech/UI alignment).
    var appLanguage: AppUILanguage {
        get { chatSpeechInputLanguage }
        set { chatSpeechInputLanguage = newValue }
    }

    private let speechService = SpeechRecognizerService()
    private let parsingCoordinator = TaskParsingCoordinator(
        localParser: LocalTaskParser(),
        llmParser: LLMTaskParserService()
    )
    private var persistenceContext: ModelContext?
    private var silenceTimerTask: Task<Void, Never>?

    func attachPersistence(_ context: ModelContext) {
        persistenceContext = context
    }

    var chatStatusDescription: String {
        let s = appLanguage.strings
        switch chatFlowState {
        case .idle: return s.voiceTapToSpeak
        case .listening: return s.voiceListening
        case .processing: return s.voiceProcessing
        case .success: return s.voiceReady
        case .error: return s.voiceError
        }
    }

    /// Call when app language changes while this view model may be active (e.g. chat sheet open).
    func handleAppLanguageChanged() async {
        await speechService.cancelForReset()
        cancelSilenceTimer()
        if chatFlowState == .listening {
            chatFlowState = .idle
            chatDraftText = ""
        }
    }

    func chatMicrophoneTapped() {
        switch chatFlowState {
        case .idle, .success, .error:
            Task { await chatBeginListening() }
        case .listening:
            Task { await chatFinalizeListening() }
        case .processing:
            break
        }
    }

    private func resetSilenceTimer() {
        silenceTimerTask?.cancel()
        silenceTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }

            guard let self else { return }
            if self.chatFlowState == .listening {
                await self.chatFinalizeListening()
            }
        }
    }

    private func cancelSilenceTimer() {
        silenceTimerTask?.cancel()
        silenceTimerTask = nil
    }

    func chatBeginListening() async {
        cancelSilenceTimer()

        let msgs = appLanguage.speechMessages
        if let err = await speechService.requestAuthorizationIfNeeded(messages: msgs) {
            chatMessages.append(ChatMessage(role: .assistant, text: err))
            chatFlowState = .error
            return
        }

        chatDraftText = ""

        let startError = await speechService.startRecognition(
            locale: appLanguage.speechLocale,
            messages: msgs,
            onPartialResult: { [weak self] text in
                self?.chatDraftText = text
                self?.resetSilenceTimer()
            },
            onRuntimeError: { [weak self] message in
                guard let self else { return }
                self.cancelSilenceTimer()
                self.chatMessages.append(ChatMessage(role: .assistant, text: message))
                self.chatFlowState = .error
            }
        )

        if let startError {
            chatMessages.append(ChatMessage(role: .assistant, text: startError))
            chatFlowState = .error
            return
        }

        chatFlowState = .listening
        resetSilenceTimer()
    }

    func chatFinalizeListening() async {
        silenceTimerTask?.cancel()
        silenceTimerTask = nil
        chatFlowState = .processing
        let outcome = await speechService.stopRecognition()
        let strings = appLanguage.strings
        let speechMsgs = appLanguage.speechMessages
        switch outcome {
        case .success(let text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            chatDraftText = ""
            if trimmed.isEmpty {
                chatMessages.append(
                    ChatMessage(role: .assistant, text: strings.chatEmptyTranscript)
                )
                chatFlowState = .error
            } else {
                chatMessages.append(ChatMessage(role: .user, text: trimmed))
                await applyChatParse(transcript: trimmed)
            }
        case .failure(let error):
            chatDraftText = ""
            chatMessages.append(
                ChatMessage(role: .assistant, text: localizedStopFailure(error, speechMsgs: speechMsgs))
            )
            parsedCommand = nil
            chatFlowState = .error
        }
    }

    private func localizedStopFailure(_ error: Error, speechMsgs: SpeechServiceMessages) -> String {
        let ns = error as NSError
        if ns.domain == VocaTimeSpeechDomain.name, let code = VocaTimeSpeechErrorCode(rawValue: ns.code) {
            switch code {
            case .nothingToStop: return speechMsgs.nothingToStop
            case .interrupted: return speechMsgs.interrupted
            case .recognitionStopped: return speechMsgs.recognitionStopped
            case .generic: break
            }
        }
        return ns.localizedDescription
    }

    private func applyChatParse(transcript: String) async {
        let command = await parsingCoordinator.parse(
            text: transcript,
            now: Date(),
            localeIdentifier: appLanguage.uiLocaleIdentifier,
            timeZoneIdentifier: TimeZone.current.identifier
        )
        parsedCommand = command
        let reply = confirmationMessage(for: command, userTranscript: transcript)
        chatMessages.append(ChatMessage(role: .assistant, text: reply))
        if let ctx = persistenceContext {
            TaskItem.insertFromParsedCommand(command, context: ctx)
        }
        chatFlowState = .success
    }

    private func confirmationMessage(for command: ParsedCommand, userTranscript: String) -> String {
        let s = appLanguage.strings
        if command.actionType == .unknown {
            let name = command.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let label: String
            if name.isEmpty {
                label = s.chatYourTask
            } else if appLanguage == .en {
                label = "“\(name)”"
            } else {
                label = "「\(name)」"
            }
            return String(format: s.chatUnknownSchedule, label)
        }

        let low = userTranscript.lowercased()
        if command.actionType == .reminder {
            if let n = extractLeadingMinutes(from: low) {
                return n == 1
                    ? String(format: s.chatReminderMinutes, n)
                    : String(format: s.chatReminderMinutesPlural, n)
            }
            if let n = extractLeadingHours(from: low) {
                return n == 1
                    ? String(format: s.chatReminderHours, n)
                    : String(format: s.chatReminderHoursPlural, n)
            }
            if let when = command.reminderDate {
                let t = replyDateFormatter.string(from: when)
                return String(format: s.chatReminderAt, t, command.title)
            }
            return String(format: s.chatReminderAbout, command.title)
        }
        if command.actionType == .calendarEvent {
            if let when = command.startDate {
                let t = replyDateFormatter.string(from: when)
                return String(format: s.chatEventAt, command.title, t)
            }
            return String(format: s.chatEventCalendar, command.title)
        }
        return s.chatTryRemind
    }

    private var replyDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = appLanguage.locale
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    private func extractLeadingMinutes(from low: String) -> Int? {
        matchNumber(prefixPattern: #"in\s+(\d+)\s+minutes?"#, in: low)
    }

    private func extractLeadingHours(from low: String) -> Int? {
        matchNumber(prefixPattern: #"in\s+(\d+)\s+hours?"#, in: low)
    }

    private func matchNumber(prefixPattern: String, in low: String) -> Int? {
        let ns = low as NSString
        guard let regex = try? NSRegularExpression(pattern: "^\(prefixPattern)", options: .caseInsensitive),
              let m = regex.firstMatch(in: low, options: [], range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges >= 2,
              let r = Range(m.range(at: 1), in: low),
              let n = Int(low[r]), n > 0
        else { return nil }
        return n
    }
}
