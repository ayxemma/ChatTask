import AVFoundation
import Foundation
import Speech

enum VocaTimeSpeechErrorCode: Int {
    case generic = 0
    case nothingToStop = 1
    case interrupted = 2
    case recognitionStopped = 3
}

enum VocaTimeSpeechDomain {
    static let name = "VocaTimeSpeech"
}

private func speechRecognitionError(code: VocaTimeSpeechErrorCode, fallbackMessage: String) -> Error {
    NSError(domain: VocaTimeSpeechDomain.name, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: fallbackMessage])
}

/// Streams microphone audio to on-device/server speech recognition. All public methods and callbacks are main-actor isolated.
@MainActor
final class SpeechRecognizerService {
    /// Strong reference for the active session only; created per `startRecognition(locale:)`.
    private var sessionRecognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var onPartialResult: ((String) -> Void)?
    private var onRuntimeError: ((String) -> Void)?
    private var sessionMessages: SpeechServiceMessages?

    private var lastTranscript: String = ""
    private var isStopping = false
    private var stopContinuation: CheckedContinuation<Result<String, Error>, Never>?
    private var stopTimeoutTask: Task<Void, Never>?

    /// Stops any in-flight session when the user dismisses the flow (e.g. Done).
    func cancelForReset() async {
        await cancelOngoingSessionSilently()
    }

    /// Returns `nil` if authorized (or became authorized), otherwise a user-readable error.
    func requestAuthorizationIfNeeded(messages: SpeechServiceMessages) async -> String? {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        switch speechStatus {
        case .authorized:
            break
        case .notDetermined:
            let newStatus = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            }
            if newStatus != .authorized {
                return speechAuthErrorMessage(for: newStatus, messages: messages)
            }
        case .denied, .restricted:
            return speechAuthErrorMessage(for: speechStatus, messages: messages)
        @unknown default:
            return messages.speechNotAvailable
        }

        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch micStatus {
        case .authorized:
            return nil
        case .notDetermined:
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { continuation.resume(returning: $0) }
            }
            if granted {
                return nil
            }
            return messages.micDeniedSettings
        case .denied, .restricted:
            return messages.micDenied
        @unknown default:
            return messages.micUnavailable
        }
    }

    /// Starts capturing audio and recognition for the given locale. Returns an immediate error string if setup fails; otherwise `nil`.
    func startRecognition(
        locale: Locale,
        messages: SpeechServiceMessages,
        onPartialResult: @escaping (String) -> Void,
        onRuntimeError: @escaping (String) -> Void
    ) async -> String? {
        stopTimeoutTask?.cancel()
        stopTimeoutTask = nil
        await cancelOngoingSessionSilently()

        let recognizer = SFSpeechRecognizer(locale: locale)
        guard let recognizer else {
            return String(format: messages.unsupportedLocale, locale.identifier)
        }
        guard recognizer.isAvailable else {
            return String(format: messages.localeUnavailable, locale.identifier)
        }

        sessionRecognizer = recognizer
        sessionMessages = messages

        self.onPartialResult = onPartialResult
        self.onRuntimeError = onRuntimeError
        lastTranscript = ""
        isStopping = false

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return String(format: messages.micUseFailed, error.localizedDescription)
        }

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            try? session.setActive(false)
            return messages.micInputUnavailable
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine = engine
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                self.handleRecognitionCallback(recognitionResult: result, error: error)
            }
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            cleanupAfterFailedStart()
            return String(format: messages.audioStartFailed, error.localizedDescription)
        }

        return nil
    }

    /// Ends audio input and waits for a final transcript (or timeout using the last partial result).
    func stopRecognition() async -> Result<String, Error> {
        guard audioEngine != nil || recognitionTask != nil else {
            let trimmed = lastTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return .success(trimmed)
            }
            return .failure(speechRecognitionError(code: .nothingToStop, fallbackMessage: "Nothing to stop — start listening first."))
        }

        isStopping = true
        recognitionRequest?.endAudio()
        removeTapAndStopEngine()

        return await withCheckedContinuation { continuation in
            stopContinuation = continuation

            stopTimeoutTask?.cancel()
            stopTimeoutTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                self.finishStopIfNeeded(
                    outcome: .success(self.lastTranscript.trimmingCharacters(in: .whitespacesAndNewlines))
                )
            }
        }
    }

    private func handleRecognitionCallback(recognitionResult: SFSpeechRecognitionResult?, error: Error?) {
        if let error {
            let ns = error as NSError
            if isStopping, ns.domain == "kAFAssistantErrorDomain", ns.code == 216 {
                finishStopIfNeeded(outcome: .success(lastTranscript.trimmingCharacters(in: .whitespacesAndNewlines)))
                return
            }
            if isStopping {
                let trimmed = lastTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    finishStopIfNeeded(outcome: .failure(error))
                } else {
                    finishStopIfNeeded(outcome: .success(trimmed))
                }
                return
            }
            let msgs = sessionMessages ?? .english
            onRuntimeError?(userFacingRecognitionError(error, messages: msgs))
            teardownAfterFailure()
            return
        }

        guard let recognitionResult else { return }

        let text = recognitionResult.bestTranscription.formattedString
        lastTranscript = text
        onPartialResult?(text)

        if recognitionResult.isFinal {
            finishStopIfNeeded(outcome: .success(text.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
    }

    private func finishStopIfNeeded(outcome: Result<String, Error>) {
        stopTimeoutTask?.cancel()
        stopTimeoutTask = nil
        if let cont = stopContinuation {
            stopContinuation = nil
            cont.resume(returning: outcome)
        }
        fullTeardown()
    }

    private func removeTapAndStopEngine() {
        let engine = audioEngine
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine?.reset()
    }

    private func teardownAfterFailure() {
        if let cont = stopContinuation {
            cont.resume(returning: .failure(speechRecognitionError(code: .recognitionStopped, fallbackMessage: "Recognition stopped.")))
        }
        stopContinuation = nil
        stopTimeoutTask?.cancel()
        stopTimeoutTask = nil
        fullTeardown()
    }

    private func cleanupAfterFailedStart() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            engine.reset()
        }
        audioEngine = nil
        sessionRecognizer = nil
        onPartialResult = nil
        onRuntimeError = nil
        sessionMessages = nil
        isStopping = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func fullTeardown() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine = nil
        sessionRecognizer = nil
        onPartialResult = nil
        onRuntimeError = nil
        sessionMessages = nil
        isStopping = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func cancelOngoingSessionSilently() async {
        stopTimeoutTask?.cancel()
        stopTimeoutTask = nil
        if let cont = stopContinuation {
            cont.resume(returning: .failure(speechRecognitionError(code: .interrupted, fallbackMessage: "Interrupted.")))
        }
        stopContinuation = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            engine.reset()
        }
        audioEngine = nil
        sessionRecognizer = nil
        onPartialResult = nil
        onRuntimeError = nil
        sessionMessages = nil
        isStopping = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        await Task.yield()
    }

    private func speechAuthErrorMessage(for status: SFSpeechRecognizerAuthorizationStatus, messages: SpeechServiceMessages) -> String {
        switch status {
        case .denied:
            return messages.speechDeniedSettings
        case .restricted:
            return messages.speechRestricted
        case .notDetermined:
            return messages.speechNotDetermined
        default:
            return messages.speechNotAllowed
        }
    }

    private func userFacingRecognitionError(_ error: Error, messages: SpeechServiceMessages) -> String {
        let ns = error as NSError
        if ns.domain == "kAFAssistantErrorDomain", ns.code == 203 {
            return messages.noSpeechDetected
        }
        if ns.domain == "kAFAssistantErrorDomain", ns.code == 216 {
            return messages.recognitionCanceled
        }
        return String(format: messages.recognitionFailedFormat, error.localizedDescription)
    }
}
