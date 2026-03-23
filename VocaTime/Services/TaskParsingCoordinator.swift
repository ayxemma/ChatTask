import Foundation

/// Runs the local parser first, then optionally an LLM parser; falls back to a minimal unknown command when needed.
struct TaskParsingCoordinator {
    let localParser: any TaskParsing
    var llmParser: (any TaskParsing)?

    init(localParser: any TaskParsing = LocalTaskParser(), llmParser: (any TaskParsing)? = nil) {
        self.localParser = localParser
        self.llmParser = llmParser
    }

    func parse(
        text: String,
        now: Date,
        localeIdentifier: String,
        timeZoneIdentifier: String
    ) async -> ParsedCommand {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let input = trimmed.isEmpty ? text : trimmed

        do {
            let local = try await localParser.parse(
                text: input,
                now: now,
                localeIdentifier: localeIdentifier,
                timeZoneIdentifier: timeZoneIdentifier
            )
            if local.actionType != .unknown {
                return local
            }
            if let llm = llmParser {
                do {
                    return try await llm.parse(
                        text: input,
                        now: now,
                        localeIdentifier: localeIdentifier,
                        timeZoneIdentifier: timeZoneIdentifier
                    )
                } catch {
                    return local
                }
            }
            return local
        } catch {
            if let llm = llmParser {
                do {
                    return try await llm.parse(
                        text: input,
                        now: now,
                        localeIdentifier: localeIdentifier,
                        timeZoneIdentifier: timeZoneIdentifier
                    )
                } catch {
                    return Self.fallbackUnknown(text: input, localeIdentifier: localeIdentifier)
                }
            }
            return Self.fallbackUnknown(text: input, localeIdentifier: localeIdentifier)
        }
    }

    private static func fallbackUnknown(text: String, localeIdentifier: String) -> ParsedCommand {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmed.isEmpty ? "Untitled" : trimmed
        let languageCode = localeIdentifier.split(separator: "-").first.map(String.init)
        return ParsedCommand(
            originalText: text,
            actionType: .unknown,
            title: title,
            notes: nil,
            startDate: nil,
            endDate: nil,
            reminderDate: nil,
            confidence: nil,
            parserSource: .unknown,
            languageCode: languageCode
        )
    }
}
