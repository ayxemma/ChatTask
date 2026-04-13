import SwiftData
import SwiftUI

struct TaskDetailView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.appUILanguage) private var appUILanguage

    @FocusState private var titleFocused: Bool

    @State private var scheduleEnabled: Bool
    @State private var daySelection: Date
    @State private var specificTimeEnabled: Bool
    @State private var timeSelection: Date
    @State private var reminderOffset: ReminderOffset

    private var calendar: Calendar { .current }

    private var strings: AppStrings { appUILanguage.strings }

    init(task: TaskItem) {
        self.task = task
        let cal = Calendar.current
        if let s = task.scheduledDate {
            _scheduleEnabled = State(initialValue: true)
            _daySelection = State(initialValue: cal.startOfDay(for: s))
            _specificTimeEnabled = State(initialValue: TaskScheduleFormatting.hasWallClockTime(s, calendar: cal))
            _timeSelection = State(initialValue: s)
        } else {
            _scheduleEnabled = State(initialValue: false)
            _daySelection = State(initialValue: cal.startOfDay(for: Date()))
            _specificTimeEnabled = State(initialValue: false)
            _timeSelection = State(initialValue: Date())
        }
        let offsetMinutes = task.reminderOffsetMinutes ?? ReminderOffset.globalDefault.rawValue
        _reminderOffset = State(initialValue: ReminderOffset.nearest(to: offsetMinutes))
    }

    var body: some View {
        let s = strings
        Form {
            Section(s.taskSection) {
                TextField(s.titlePlaceholder, text: titleBinding)
                    .focused($titleFocused)

                TextField(s.notesPlaceholder, text: notesBinding, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section(s.scheduleSection) {
                Toggle(s.scheduledToggle, isOn: $scheduleEnabled)
                    .onChange(of: scheduleEnabled) { _, new in
                        if new {
                            if task.scheduledDate == nil {
                                daySelection = calendar.startOfDay(for: Date())
                                specificTimeEnabled = false
                                timeSelection = Date()
                            }
                        }
                        flushScheduleToTask()
                    }

                if scheduleEnabled {
                    DatePicker(s.datePickerLabel, selection: $daySelection, displayedComponents: .date)
                        .environment(\.locale, locale)
                        .onChange(of: daySelection) { _, _ in
                            flushScheduleToTask()
                        }

                    Toggle(s.specificTime, isOn: $specificTimeEnabled)
                        .onChange(of: specificTimeEnabled) { _, _ in
                            flushScheduleToTask()
                        }

                    if specificTimeEnabled {
                        DatePicker(s.timePickerLabel, selection: $timeSelection, displayedComponents: .hourAndMinute)
                            .environment(\.locale, locale)
                            .onChange(of: timeSelection) { _, _ in
                                flushScheduleToTask()
                            }

                        Picker(s.reminderLabel, selection: $reminderOffset) {
                            ForEach(ReminderOffset.allCases) { option in
                                Text(option.displayLabel).tag(option)
                            }
                        }
                        .onChange(of: reminderOffset) { _, new in
                            task.reminderOffsetMinutes = new.rawValue
                            task.updatedAt = Date()
                            TaskReminderService.shared.schedule(for: task)
                        }
                    }
                }

                Text(s.scheduleHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(s.completed, isOn: completionBinding)
            }

            Section {
                Button(role: .destructive) {
                    TaskReminderService.shared.cancel(taskID: task.id)
                    modelContext.delete(task)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Text(s.deleteTask)
                }
            }
        }
        .navigationTitle(s.taskSection)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            titleFocused = true
        }
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { task.title },
            set: { new in
                task.title = new
                task.updatedAt = Date()
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { task.notes ?? "" },
            set: { new in
                let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
                task.notes = trimmed.isEmpty ? nil : trimmed
                task.updatedAt = Date()
            }
        )
    }

    private var completionBinding: Binding<Bool> {
        Binding(
            get: { task.isCompleted },
            set: { new in
                task.isCompleted = new
                task.completedAt = new ? Date() : nil
                task.updatedAt = Date()
                if new {
                    TaskReminderService.shared.cancel(taskID: task.id)
                } else {
                    TaskReminderService.shared.schedule(for: task)
                }
            }
        )
    }

    private func flushScheduleToTask() {
        guard scheduleEnabled else {
            task.scheduledDate = nil
            task.reminderOffsetMinutes = nil
            task.updatedAt = Date()
            TaskReminderService.shared.cancel(taskID: task.id)
            return
        }
        task.scheduledDate = TaskScheduleHelpers.scheduledDate(
            calendar: calendar,
            hasDate: true,
            daySelection: daySelection,
            hasSpecificTime: specificTimeEnabled,
            timeSelection: timeSelection
        )
        task.reminderOffsetMinutes = specificTimeEnabled ? reminderOffset.rawValue : nil
        task.updatedAt = Date()
        TaskReminderService.shared.schedule(for: task)
    }
}

private struct TaskDetailPreviewHost: View {
    private let container: ModelContainer
    private let task: TaskItem

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: TaskItem.self, configurations: config)
        let t = TaskItem(title: "Preview task", notes: "Note", scheduledDate: Date())
        c.mainContext.insert(t)
        container = c
        task = t
    }

    var body: some View {
        NavigationStack {
            TaskDetailView(task: task)
                .environment(\.appUILanguage, .en)
                .environment(\.locale, Locale(identifier: "en_US"))
        }
        .modelContainer(container)
    }
}

#Preview {
    TaskDetailPreviewHost()
}
