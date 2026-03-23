import Foundation

enum TaskParsingError: Error, Equatable {
    case llmNotImplemented
}

protocol TaskParsing {
    func parse(
        text: String,
        now: Date,
        localeIdentifier: String,
        timeZoneIdentifier: String
    ) async throws -> ParsedCommand
}

/// Wraps `IntentParserService` for the shared async parsing protocol (timezone-aware calendar per call).
struct LocalTaskParser: TaskParsing {
    func parse(
        text: String,
        now: Date,
        localeIdentifier: String,
        timeZoneIdentifier: String
    ) async throws -> ParsedCommand {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        let languageCode = localeIdentifier.split(separator: "-").first.map(String.init)
        let service = IntentParserService(calendar: calendar, referenceDate: now)
        switch service.parse(text, languageCode: languageCode) {
        case .success(let command):
            return command
        case .failure(let error):
            throw error
        }
    }
}
