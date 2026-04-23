import Foundation

struct LLMTaskParseResponse: Decodable {
    // ── Create-task fields ────────────────────────────────────
    let title: String?
    let notes: String?
    let actionType: String?
    let scheduledAt: String?
    let endAt: String?
    let hasSpecificTime: Bool?
    let languageCode: String?
    let confidence: Double?

    // ── Edit-command fields ───────────────────────────────────
    /// ISO8601 time reference for the existing task to act on.
    let targetTime: String?
    /// ISO8601 new scheduled time (rescheduleTask only).
    let newScheduledAt: String?
    /// Text to append to the existing task's notes (appendToTask only).
    let appendText: String?
    /// New title (updateTaskTitle only).
    let newTitle: String?

    enum CodingKeys: String, CodingKey {
        case title, notes, confidence
        case actionType     = "action_type"
        case scheduledAt    = "scheduled_at"
        case endAt          = "end_at"
        case hasSpecificTime = "has_specific_time"
        case languageCode   = "language_code"
        case targetTime     = "target_time"
        case newScheduledAt = "new_scheduled_at"
        case appendText     = "append_text"
        case newTitle       = "new_title"
    }
}
