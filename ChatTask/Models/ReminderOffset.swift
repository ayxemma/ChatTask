import Foundation

/// The supported lead-time options for task reminder notifications.
///
/// A value of `.atTime` means the notification fires exactly at the task's
/// scheduled time. All other values fire that many minutes earlier.
enum ReminderOffset: Int, CaseIterable, Identifiable {
    case atTime     = 0
    case fiveMin    = 5
    case fifteenMin = 15
    case thirtyMin  = 30
    case oneHour    = 60

    var id: Int { rawValue }

    var displayLabel: String {
        switch self {
        case .atTime:     return "At time of task"
        case .fiveMin:    return "5 min before"
        case .fifteenMin: return "15 min before"
        case .thirtyMin:  return "30 min before"
        case .oneHour:    return "1 hr before"
        }
    }

    /// Returns the UserDefaults key used to persist the global default.
    static let defaultsKey = "reminderDefaultMinutes"

    /// The global default offset (read from UserDefaults; falls back to `.atTime`).
    static var globalDefault: ReminderOffset {
        nearest(to: UserDefaults.standard.integer(forKey: defaultsKey))
    }

    /// The closest matching case for an arbitrary raw-minute value.
    static func nearest(to minutes: Int) -> ReminderOffset {
        allCases.first { $0.rawValue == minutes } ?? .atTime
    }
}
