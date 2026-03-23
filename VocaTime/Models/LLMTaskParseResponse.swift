import Foundation

/// Expected JSON shape for a future LLM task-parsing API. Not used by the placeholder parser yet.
struct LLMTaskParseResponse: Decodable {
    let title: String?
    let notes: String?
    let actionType: String?
    let scheduledAt: String?
    let endAt: String?
    let hasSpecificTime: Bool?
    let languageCode: String?
    let confidence: Double?

    enum CodingKeys: String, CodingKey {
        case title, notes, confidence
        case actionType = "action_type"
        case scheduledAt = "scheduled_at"
        case endAt = "end_at"
        case hasSpecificTime = "has_specific_time"
        case languageCode = "language_code"
    }
}
