// OpenAI API key lives in `Secrets.swift` (gitignored). Copy `Secrets.swift.example` → `Secrets.swift` if missing.

import Foundation
import os.log

enum LLMError: Error {
    case invalidResponse
    case decodingFailed
}

struct LLMTaskParserService: TaskParsing {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocaTime", category: "TaskParsing")

    private var apiKey: String { Secrets.openAIAPIKey }
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini"

    func parse(text: String, now: Date, localeIdentifier: String, timeZoneIdentifier: String) async throws -> ParsedCommand {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        let nowString = formatter.string(from: now)

        let systemPrompt = """
        You are a highly capable multilingual task parsing assistant.
        The user will provide a command which may be in English, Chinese, or a mixture of both.
        Understand the intent, translate or normalize the title to the primary language spoken, and extract the schedule.

        Current Date/Time: \(nowString)
        Timezone: \(timeZoneIdentifier)

        Return ONLY a valid JSON object matching this schema. Do not wrap it in markdown blocks.
        {
          "title": "The name of the task",
          "notes": "Any extra contextual details",
          "action_type": "reminder" | "calendarEvent" | "unknown",
          "scheduled_at": "ISO8601 formatted string if a specific date or time is mentioned, else null",
          "end_at": "ISO8601 formatted string if an end time is mentioned, else null",
          "has_specific_time": true if a specific clock time is mentioned (false if it's just a day/Anytime),
          "language_code": "en" | "zh" | "mixed",
          "confidence": 0.9
        }
        """

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.0
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse
        let statusCode = http?.statusCode ?? -1
        Self.log.info("[LLM] httpStatusCode=\(statusCode, privacy: .public)")

        let rawResponseBody = String(data: data, encoding: .utf8) ?? "<non-UTF8 body, \(data.count) bytes>"
        Self.logLongString(prefix: "[LLM] rawHttpResponseBody", text: rawResponseBody)

        if let http, !(200...299).contains(http.statusCode) {
            Self.log.error("[LLM] request failed httpStatusCode=\(statusCode, privacy: .public)")
            throw LLMError.invalidResponse
        }

        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let apiResponse: OpenAIResponse
        do {
            apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch {
            Self.log.error("[LLM] OpenAI envelope decode failed error=\(String(describing: error), privacy: .public)")
            throw LLMError.decodingFailed
        }

        guard let jsonString = apiResponse.choices.first?.message.content else {
            Self.log.error("[LLM] missing choices[0].message.content")
            throw LLMError.invalidResponse
        }

        Self.logLongString(prefix: "[LLM] modelMessageContentRaw", text: jsonString)

        guard let jsonData = jsonString.data(using: .utf8) else {
            Self.log.error("[LLM] model message content is not valid UTF-8")
            throw LLMError.invalidResponse
        }

        let parsed: LLMTaskParseResponse
        do {
            parsed = try JSONDecoder().decode(LLMTaskParseResponse.self, from: jsonData)
        } catch {
            Self.log.error("[LLM] LLMTaskParseResponse decode failed error=\(String(describing: error), privacy: .public)")
            throw LLMError.decodingFailed
        }

        Self.logDecodedLLMResponse(parsed)

        let tz = TimeZone(identifier: timeZoneIdentifier) ?? .current

        var scheduledDate: Date?
        if let dateString = parsed.scheduledAt {
            let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                scheduledDate = nil
            } else {
                scheduledDate = Self.parseISO8601(dateString, timeZone: tz)
                if scheduledDate == nil {
                    Self.log.warning("[LLM] scheduled_at returned but could not parse Date raw=\(dateString, privacy: .public)")
                }
            }
        }

        var endDate: Date?
        if let dateString = parsed.endAt {
            let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                endDate = nil
            } else {
                endDate = Self.parseISO8601(dateString, timeZone: tz)
                if endDate == nil {
                    Self.log.warning("[LLM] end_at returned but could not parse Date raw=\(dateString, privacy: .public)")
                }
            }
        }

        let (actionType, actionTypeUnmapped) = Self.mapLLMActionType(parsed.actionType)
        if actionTypeUnmapped {
            Self.log.warning("[LLM] action_type returned but did not map to ActionType raw=\(parsed.actionType ?? "nil", privacy: .public)")
        }

        let cmd = ParsedCommand(
            originalText: text,
            actionType: actionType,
            title: parsed.title ?? text,
            notes: parsed.notes,
            startDate: actionType == .calendarEvent ? scheduledDate : nil,
            endDate: endDate,
            reminderDate: actionType == .reminder ? scheduledDate : nil,
            confidence: parsed.confidence,
            parserSource: .llm,
            languageCode: parsed.languageCode
        )

        Self.logFinalParsedCommand(cmd)
        return cmd
    }

    private static func logDecodedLLMResponse(_ p: LLMTaskParseResponse) {
        let sched = p.scheduledAt ?? "nil"
        let end = p.endAt ?? "nil"
        log.info("""
            [LLM] decoded LLMTaskParseResponse title=\(p.title ?? "nil", privacy: .public) notes=\(p.notes ?? "nil", privacy: .public) \
            action_type=\(p.actionType ?? "nil", privacy: .public) scheduled_at=\(sched, privacy: .public) end_at=\(end, privacy: .public) \
            has_specific_time=\(String(describing: p.hasSpecificTime), privacy: .public) language_code=\(p.languageCode ?? "nil", privacy: .public) \
            confidence=\(String(describing: p.confidence), privacy: .public)
            """)
    }

    private static func logFinalParsedCommand(_ cmd: ParsedCommand) {
        let start = cmd.startDate.map { ISO8601DateFormatter().string(from: $0) } ?? "nil"
        let reminder = cmd.reminderDate.map { ISO8601DateFormatter().string(from: $0) } ?? "nil"
        log.info("[LLM] final ParsedCommand actionType=\(String(describing: cmd.actionType), privacy: .public) title=\(cmd.title, privacy: .public) startDate=\(start, privacy: .public) reminderDate=\(reminder, privacy: .public) parserSource=\(String(describing: cmd.parserSource), privacy: .public)")
    }

    /// Chunked logging for long strings (os_log may truncate single messages).
    private static func logLongString(prefix: String, text: String, chunkSize: Int = 800) {
        if text.count <= chunkSize {
            log.info("\(prefix, privacy: .public)=\(text, privacy: .public)")
            return
        }
        var startIndex = text.startIndex
        var part = 1
        while startIndex < text.endIndex {
            let endIndex = text.index(startIndex, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            let slice = String(text[startIndex..<endIndex])
            log.info("\(prefix, privacy: .public) part\(part, privacy: .public)=\(slice, privacy: .public)")
            startIndex = endIndex
            part += 1
        }
    }

    /// Maps JSON `action_type` values to `ActionType` (tolerates snake_case and casing drift).
    /// `unmapped` is true when a non-empty raw value could not be mapped (excluding explicit "unknown").
    private static func mapLLMActionType(_ raw: String?) -> (ActionType, unmapped: Bool) {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return (.unknown, false)
        }
        let collapsed = raw.replacingOccurrences(of: "_", with: "").lowercased()
        switch collapsed {
        case "reminder": return (.reminder, false)
        case "calendarevent": return (.calendarEvent, false)
        case "unknown": return (.unknown, false)
        default:
            if let t = ActionType(rawValue: raw) {
                return (t, false)
            }
            return (.unknown, true)
        }
    }

    /// Parses ISO8601 strings from the model: full date-time (with optional fractional seconds) or date-only.
    private static func parseISO8601(_ string: String, timeZone: TimeZone) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let f1 = ISO8601DateFormatter()
        f1.timeZone = timeZone
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: trimmed) { return d }

        let f2 = ISO8601DateFormatter()
        f2.timeZone = timeZone
        f2.formatOptions = [.withInternetDateTime]
        if let d = f2.date(from: trimmed) { return d }

        let f3 = ISO8601DateFormatter()
        f3.timeZone = timeZone
        f3.formatOptions = [.withFullDate]
        if let d = f3.date(from: trimmed) { return d }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let patterns = ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"]
        for pattern in patterns {
            let df = DateFormatter()
            df.calendar = calendar
            df.timeZone = timeZone
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = pattern
            if let d = df.date(from: trimmed) { return d }
        }
        return nil
    }
}
