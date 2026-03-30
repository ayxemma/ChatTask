import SwiftData
import SwiftUI

enum TaskScheduleFormatting {
    static func hasWallClockTime(_ date: Date, calendar: Calendar = .current) -> Bool {
        let h = calendar.component(.hour, from: date)
        let m = calendar.component(.minute, from: date)
        let s = calendar.component(.second, from: date)
        return !(h == 0 && m == 0 && s == 0)
    }
}

enum TaskRowScheduleContext {
    case overdue
    case today
    case upcoming
    case done
    case calendar
}

struct TaskRowCompletionButton: View {
    @Bindable var task: TaskItem
    @Environment(\.appUILanguage) private var appUILanguage

    var body: some View {
        let s = appUILanguage.strings
        Button {
            let newValue = !task.isCompleted
            task.isCompleted = newValue
            task.completedAt = newValue ? Date() : nil
            task.updatedAt = Date()
        } label: {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.isCompleted ? s.markIncomplete : s.markComplete)
    }
}

struct TaskRowMainContent: View {
    @Bindable var task: TaskItem
    var scheduleContext: TaskRowScheduleContext

    @Environment(\.locale) private var locale
    @Environment(\.appUILanguage) private var appUILanguage

    private var calendar: Calendar { .current }

    private var strings: AppStrings { appUILanguage.strings }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(timePrefix)
                .font(.subheadline)
                .fontWeight(timeFontWeight)
                .monospacedDigit()
                .foregroundStyle(timeForegroundStyle)
                .frame(width: Self.timeColumnWidth, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(titleForegroundColor)
                    .strikethrough(task.isCompleted)

                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough(task.isCompleted)
                }

                if showUpcomingDaySubtitle, let d = task.scheduledDate {
                    Text(d.formatted(Date.FormatStyle().weekday(.abbreviated).month(.abbreviated).day().locale(locale)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .strikethrough(task.isCompleted)
                }

                if showOverdueDaySubtitle, let d = task.scheduledDate {
                    Text(d.formatted(Date.FormatStyle().weekday(.abbreviated).month(.abbreviated).day().locale(locale)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .strikethrough(task.isCompleted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var timePrefix: String {
        let s = strings
        guard let d = task.scheduledDate else { return s.anytime }
        guard TaskScheduleFormatting.hasWallClockTime(d, calendar: calendar) else { return s.anytime }
        return d.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
    }

    private var showUpcomingDaySubtitle: Bool {
        scheduleContext == .upcoming && task.scheduledDate != nil
    }

    private var showOverdueDaySubtitle: Bool {
        guard scheduleContext == .overdue, let d = task.scheduledDate else { return false }
        return !calendar.isDate(d, inSameDayAs: Date())
    }

    private var treatAsOverdueInCalendar: Bool {
        scheduleContext == .calendar
            && !task.isCompleted
            && (task.scheduledDate.map { $0 < Date() } ?? false)
    }

    private var timeFontWeight: Font.Weight {
        if scheduleContext == .overdue, !task.isCompleted {
            return .semibold
        }
        if treatAsOverdueInCalendar {
            return .semibold
        }
        return .regular
    }

    private var timeForegroundStyle: AnyShapeStyle {
        if task.isCompleted { return AnyShapeStyle(.tertiary) }
        if scheduleContext == .overdue { return AnyShapeStyle(Color.orange) }
        if treatAsOverdueInCalendar { return AnyShapeStyle(Color.orange) }
        return AnyShapeStyle(.secondary)
    }

    private var titleForegroundColor: Color {
        task.isCompleted ? Color.secondary : Color.primary
    }

    private static let timeColumnWidth: CGFloat = 82
}

struct TaskRowView: View {
    @Bindable var task: TaskItem
    var emphasizeCompleted: Bool
    var scheduleContext: TaskRowScheduleContext

    @Environment(\.locale) private var locale
    @Environment(\.appUILanguage) private var appUILanguage

    private var calendar: Calendar { .current }

    private var strings: AppStrings { appUILanguage.strings }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            TaskRowCompletionButton(task: task)
            TaskRowMainContent(task: task, scheduleContext: scheduleContext)
        }
        .padding(.vertical, 4)
        .opacity(emphasizeCompleted && task.isCompleted ? 0.75 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var accessibilityLabelText: String {
        let s = strings
        var parts: [String] = []
        if let d = task.scheduledDate, TaskScheduleFormatting.hasWallClockTime(d, calendar: calendar) {
            parts.append(d.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale)))
        } else {
            parts.append(s.anytime)
        }
        parts.append(task.title)
        if let n = task.notes, !n.isEmpty { parts.append(n) }
        return parts.joined(separator: ", ")
    }
}

/// Completion control stays independent; main content navigates to detail.
struct TaskNavigableRow: View {
    @Bindable var task: TaskItem
    var emphasizeCompleted: Bool
    var scheduleContext: TaskRowScheduleContext

    @Environment(\.appUILanguage) private var appUILanguage

    private var strings: AppStrings { appUILanguage.strings }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            TaskRowCompletionButton(task: task)
            NavigationLink {
                TaskDetailView(task: task)
            } label: {
                TaskRowMainContent(task: task, scheduleContext: scheduleContext)
            }
            .buttonStyle(.plain)
            .accessibilityHint(strings.editTaskDetails)
        }
        .padding(.vertical, 4)
        .opacity(emphasizeCompleted && task.isCompleted ? 0.75 : 1)
        .accessibilityElement(children: .combine)
    }
}
