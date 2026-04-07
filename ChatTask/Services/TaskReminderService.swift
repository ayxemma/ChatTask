import Foundation
import UserNotifications

/// Schedules, updates, and cancels local notifications for task reminders.
///
/// - Call `schedule(for:)` when a task is created or edited.
///   It always cancels any existing pending notification for that task first,
///   so it doubles as an update.
/// - Call `cancel(taskID:)` when a task is deleted or marked complete.
///
/// Only tasks with a future, wall-clock-specific `scheduledDate` receive a notification.
/// Date-only tasks (midnight, no specific time) are intentionally skipped.
struct TaskReminderService {
    static let shared = TaskReminderService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Public API

    func schedule(for task: TaskItem) {
        let identifier = task.id.uuidString
        // Cancel any existing pending notification — this makes schedule() work as an upsert.
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard
            !task.isCompleted,
            let date = task.scheduledDate,
            date > Date(),
            hasWallClockTime(date)
        else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = formattedBody(for: date)
        content.sound = .default

        // Fire at the exact calendar date+time of the task.
        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request  = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    func cancel(taskID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [taskID.uuidString])
    }

    // MARK: - Helpers

    /// Returns true only if the date carries a meaningful wall-clock time
    /// (i.e. is not midnight / date-only).
    private func hasWallClockTime(_ date: Date) -> Bool {
        let cal = Calendar.current
        return !(
            cal.component(.hour,   from: date) == 0 &&
            cal.component(.minute, from: date) == 0 &&
            cal.component(.second, from: date) == 0
        )
    }

    /// Builds the notification body, e.g. "Now · 5:15 PM".
    /// Uses the device locale for time formatting so the clock matches
    /// whatever the user's system is set to.
    private func formattedBody(for date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return "Now · \(f.string(from: date))"
    }
}
