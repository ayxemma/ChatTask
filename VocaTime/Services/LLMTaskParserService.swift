import Foundation

/// Placeholder for a future multilingual LLM parser. No network calls yet.
struct LLMTaskParserService: TaskParsing {
    func parse(
        text: String,
        now: Date,
        localeIdentifier: String,
        timeZoneIdentifier: String
    ) async throws -> ParsedCommand {
        throw TaskParsingError.llmNotImplemented
    }
}
