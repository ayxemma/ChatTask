import Foundation

enum ActionType: String, CaseIterable, Equatable {
    case reminder
    case calendarEvent
    case unknown
}

enum ParserSource: String, Codable, Equatable {
    case local
    case llm
    case unknown
}

struct ParsedCommand: Equatable {
    var originalText: String
    var actionType: ActionType
    var title: String
    var notes: String?
    var startDate: Date?
    var endDate: Date?
    var reminderDate: Date?
    var confidence: Double?
    var parserSource: ParserSource
    var languageCode: String?
}
