import Foundation

/// In-app language (UI + speech recognition + formatting). Distinct from `Locale.current`.
enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case english
    case chineseSimplified

    var id: String { rawValue }

    /// Short label for the Home toolbar switcher.
    var shortToolbarLabel: String {
        switch self {
        case .english: return "EN"
        case .chineseSimplified: return "中文"
        }
    }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        }
    }

    /// BCP 47 identifier for `SFSpeechRecognizer`.
    var speechRecognitionLocaleIdentifier: String {
        switch self {
        case .english: return "en-US"
        case .chineseSimplified: return "zh-CN"
        }
    }

    /// Locale for UI strings, `DateFormatter`, and SwiftUI `FormatStyle`.
    var uiLocaleIdentifier: String {
        switch self {
        case .english: return "en_US"
        case .chineseSimplified: return "zh_CN"
        }
    }

    var uiLocale: Locale {
        Locale(identifier: uiLocaleIdentifier)
    }

    var speechLocale: Locale {
        Locale(identifier: speechRecognitionLocaleIdentifier)
    }

    static func defaultForDevice() -> AppLanguage {
        let primary = Locale.preferredLanguages.first?.lowercased() ?? ""
        if primary.hasPrefix("zh-hans") || primary.hasPrefix("zh-cn") {
            return .chineseSimplified
        }
        return .english
    }

    var strings: AppStrings {
        switch self {
        case .english: return .english
        case .chineseSimplified: return .chineseSimplified
        }
    }

    var speechMessages: SpeechServiceMessages {
        switch self {
        case .english: return .english
        case .chineseSimplified: return .chineseSimplified
        }
    }
}

// MARK: - UI strings

struct AppStrings {
    let tagline: String
    let permissionStatus: String
    let tasks: String
    let today: String
    let overdue: String
    let upcoming: String
    let doneColumn: String
    let nothingHereYet: String
    let permissionsDeniedPrefix: String
    let openPermissionHint: String
    let openCommandChat: String
    let newTaskA11y: String
    let homeTab: String
    let calendarTab: String
    let calendarTitle: String
    let previousMonth: String
    let nextMonth: String
    let noTasksThisDay: String
    let commandTitle: String
    let dismissDone: String
    let titlePlaceholder: String
    let notesPlaceholder: String
    let date: String
    let time: String
    let removeDate: String
    let specificTime: String
    let none: String
    let todaySummary: String
    let tomorrowSummary: String
    let anytime: String
    let newTask: String
    let cancel: String
    let add: String
    let taskSection: String
    let scheduleSection: String
    let scheduledToggle: String
    let datePickerLabel: String
    let timePickerLabel: String
    let scheduleHint: String
    let completed: String
    let deleteTask: String
    let markComplete: String
    let markIncomplete: String
    let editTaskDetails: String
    let permissionsNavigationTitle: String
    let permissionsIntro: String
    let permissionsStatusHeader: String
    let lastMessageHeader: String
    let settings: String
    let requestAccess: String
    let permissionMicrophone: String
    let permissionSpeech: String
    let permissionNotifications: String
    let permissionCalendar: String
    let permissionMicExplanation: String
    let permissionSpeechExplanation: String
    let permissionNotificationsExplanation: String
    let permissionCalendarExplanation: String
    let statusNotAsked: String
    let statusAllowed: String
    let statusDenied: String
    let statusRestricted: String
    let statusProvisional: String
    let statusUnknown: String
    let voiceTapToSpeak: String
    let voiceListening: String
    let voiceProcessing: String
    let voiceReady: String
    let voiceError: String
    let voiceStartListening: String
    let voiceStopListening: String
    let chatEmptyTranscript: String
    let chatUnknownSchedule: String
    let chatTryRemind: String
    let chatReminderMinutes: String
    let chatReminderMinutesPlural: String
    let chatReminderHours: String
    let chatReminderHoursPlural: String
    let chatReminderAt: String
    let chatReminderAbout: String
    let chatEventAt: String
    let chatEventCalendar: String
    let chatYourTask: String
    let taskCountOne: String
    let taskCountMany: String
    let selected: String
    let permissionMicDeniedAfterRequest: String
    let permissionSpeechDeniedAfterRequest: String
    let permissionNotificationsDenied: String
    let permissionNotificationsErrorPrefix: String
    let permissionCalendarDenied: String
    let permissionCalendarErrorPrefix: String

    static let english = AppStrings(
        tagline: "Speak → Understand → Schedule → Remind",
        permissionStatus: "Permission status",
        tasks: "Tasks",
        today: "Today",
        overdue: "Overdue",
        upcoming: "Upcoming",
        doneColumn: "Done",
        nothingHereYet: "Nothing here yet",
        permissionsDeniedPrefix: "Some permissions are denied:",
        openPermissionHint: "Open Permission status to request access or fix in Settings.",
        openCommandChat: "Open command chat",
        newTaskA11y: "New task",
        homeTab: "Home",
        calendarTab: "Calendar",
        calendarTitle: "Calendar",
        previousMonth: "Previous month",
        nextMonth: "Next month",
        noTasksThisDay: "No tasks on this day",
        commandTitle: "Command",
        dismissDone: "Done",
        titlePlaceholder: "Title",
        notesPlaceholder: "Notes",
        date: "Date",
        time: "Time",
        removeDate: "Remove date",
        specificTime: "Specific time",
        none: "None",
        todaySummary: "Today",
        tomorrowSummary: "Tomorrow",
        anytime: "Anytime",
        newTask: "New Task",
        cancel: "Cancel",
        add: "Add",
        taskSection: "Task",
        scheduleSection: "Schedule",
        scheduledToggle: "Scheduled",
        datePickerLabel: "Date",
        timePickerLabel: "Time",
        scheduleHint: "Leave “Specific time” off to treat the task as Anytime on that day.",
        completed: "Completed",
        deleteTask: "Delete Task",
        markComplete: "Mark complete",
        markIncomplete: "Mark incomplete",
        editTaskDetails: "Edit task details",
        permissionsNavigationTitle: "Permissions",
        permissionsIntro: "VocaTime needs these permissions to hear you, understand speech, remind you, and add calendar events. Denied items can be changed in Settings.",
        permissionsStatusHeader: "Status",
        lastMessageHeader: "Last message",
        settings: "Settings",
        requestAccess: "Request access",
        permissionMicrophone: "Microphone",
        permissionSpeech: "Speech Recognition",
        permissionNotifications: "Notifications",
        permissionCalendar: "Calendar",
        permissionMicExplanation: "Needed to hear your voice commands.",
        permissionSpeechExplanation: "Needed to turn speech into text.",
        permissionNotificationsExplanation: "Needed to remind you at the right time.",
        permissionCalendarExplanation: "Needed to add events to your calendar.",
        statusNotAsked: "Not asked",
        statusAllowed: "Allowed",
        statusDenied: "Denied",
        statusRestricted: "Restricted",
        statusProvisional: "Provisional",
        statusUnknown: "Unknown",
        voiceTapToSpeak: "Tap the microphone to speak.",
        voiceListening: "Listening… tap again when you’re done.",
        voiceProcessing: "Processing…",
        voiceReady: "Ready for your next command.",
        voiceError: "Something went wrong — try again.",
        voiceStartListening: "Start listening",
        voiceStopListening: "Stop listening",
        chatEmptyTranscript: "I didn’t catch that. Try speaking a bit longer.",
        chatUnknownSchedule: """
            I saved %@, but I couldn’t confidently figure out a date or time from what you said.

            Open the task from Home or Calendar, tap it, and set the schedule (or leave it as Anytime) in the editor.
            """,
        chatTryRemind: "I’m not sure how to schedule that yet. Try “remind me…” or “today at 3 PM…”.",
        chatReminderMinutes: "Got it. I’ll remind you in %d minute.",
        chatReminderMinutesPlural: "Got it. I’ll remind you in %d minutes.",
        chatReminderHours: "Got it. I’ll remind you in %d hour.",
        chatReminderHoursPlural: "Got it. I’ll remind you in %d hours.",
        chatReminderAt: "Got it. I’ll remind you at %@ about “%@”.",
        chatReminderAbout: "Got it. I’ll remind you about “%@”.",
        chatEventAt: "Got it. I’ve noted “%@” for %@.",
        chatEventCalendar: "Got it. I’ve noted “%@” for your calendar.",
        chatYourTask: "your task",
        taskCountOne: "1 task",
        taskCountMany: "%d tasks",
        selected: "selected",
        permissionMicDeniedAfterRequest: "Microphone access was denied. You can enable it in Settings.",
        permissionSpeechDeniedAfterRequest: "Speech recognition was denied. You can enable it in Settings.",
        permissionNotificationsDenied: "Notifications were not allowed. You can enable them in Settings.",
        permissionNotificationsErrorPrefix: "Could not request notifications:",
        permissionCalendarDenied: "Calendar access was denied. You can enable it in Settings.",
        permissionCalendarErrorPrefix: "Calendar error:"
    )

    static let chineseSimplified = AppStrings(
        tagline: "说话 → 理解 → 安排 → 提醒",
        permissionStatus: "权限状态",
        tasks: "任务",
        today: "今天",
        overdue: "逾期",
        upcoming: "未来",
        doneColumn: "已完成",
        nothingHereYet: "暂无内容",
        permissionsDeniedPrefix: "部分权限被拒绝：",
        openPermissionHint: "打开「权限状态」以请求权限或在设置中修复。",
        openCommandChat: "打开语音指令",
        newTaskA11y: "新任务",
        homeTab: "首页",
        calendarTab: "日历",
        calendarTitle: "日历",
        previousMonth: "上个月",
        nextMonth: "下个月",
        noTasksThisDay: "当天没有任务",
        commandTitle: "指令",
        dismissDone: "完成",
        titlePlaceholder: "标题",
        notesPlaceholder: "备注",
        date: "日期",
        time: "时间",
        removeDate: "移除日期",
        specificTime: "具体时间",
        none: "无",
        todaySummary: "今天",
        tomorrowSummary: "明天",
        anytime: "随时",
        newTask: "新任务",
        cancel: "取消",
        add: "添加",
        taskSection: "任务",
        scheduleSection: "日程",
        scheduledToggle: "已计划",
        datePickerLabel: "日期",
        timePickerLabel: "时间",
        scheduleHint: "关闭「具体时间」则该任务在当天为随时。",
        completed: "已完成",
        deleteTask: "删除任务",
        markComplete: "标记为完成",
        markIncomplete: "标记为未完成",
        editTaskDetails: "编辑任务详情",
        permissionsNavigationTitle: "权限",
        permissionsIntro: "VocaTime 需要这些权限以听取语音、识别文字、发送提醒并添加日历事件。可在设置中更改已拒绝的项。",
        permissionsStatusHeader: "状态",
        lastMessageHeader: "最近提示",
        settings: "设置",
        requestAccess: "请求授权",
        permissionMicrophone: "麦克风",
        permissionSpeech: "语音识别",
        permissionNotifications: "通知",
        permissionCalendar: "日历",
        permissionMicExplanation: "用于听取语音指令。",
        permissionSpeechExplanation: "用于将语音转为文字。",
        permissionNotificationsExplanation: "用于在合适时间提醒您。",
        permissionCalendarExplanation: "用于向日历添加事件。",
        statusNotAsked: "未询问",
        statusAllowed: "已允许",
        statusDenied: "已拒绝",
        statusRestricted: "受限制",
        statusProvisional: "临时",
        statusUnknown: "未知",
        voiceTapToSpeak: "点击麦克风开始说话。",
        voiceListening: "正在聆听… 说完后再点一次结束。",
        voiceProcessing: "处理中…",
        voiceReady: "可以说下一条指令了。",
        voiceError: "出错了，请重试。",
        voiceStartListening: "开始聆听",
        voiceStopListening: "停止聆听",
        chatEmptyTranscript: "没听清，请再说长一点。",
        chatUnknownSchedule: """
            已保存 %@，但无法从您的话里确定日期或时间。

            请在首页或日历中打开该任务，点进去在编辑器里设置日程（或保留为随时）。
            """,
        chatTryRemind: "还不太会安排这类说法。试试「提醒我…」或「今天下午 3 点…」。",
        chatReminderMinutes: "好的，%d 分钟后提醒您。",
        chatReminderMinutesPlural: "好的，%d 分钟后提醒您。",
        chatReminderHours: "好的，%d 小时后提醒您。",
        chatReminderHoursPlural: "好的，%d 小时后提醒您。",
        chatReminderAt: "好的，将在 %@ 提醒您关于「%@」。",
        chatReminderAbout: "好的，将提醒您关于「%@」。",
        chatEventAt: "好的，已将「%@」记在 %@。",
        chatEventCalendar: "好的，已将「%@」记在日历上。",
        chatYourTask: "该任务",
        taskCountOne: "1 个任务",
        taskCountMany: "%d 个任务",
        selected: "已选中",
        permissionMicDeniedAfterRequest: "麦克风权限被拒绝。可在设置中开启。",
        permissionSpeechDeniedAfterRequest: "语音识别权限被拒绝。可在设置中开启。",
        permissionNotificationsDenied: "未允许通知。可在设置中开启。",
        permissionNotificationsErrorPrefix: "无法请求通知：",
        permissionCalendarDenied: "日历权限被拒绝。可在设置中开启。",
        permissionCalendarErrorPrefix: "日历错误："
    )
}

extension PermissionKind {
    func localizedTitle(strings: AppStrings) -> String {
        switch self {
        case .microphone: return strings.permissionMicrophone
        case .speech: return strings.permissionSpeech
        case .notifications: return strings.permissionNotifications
        case .calendar: return strings.permissionCalendar
        }
    }

    func localizedExplanation(strings: AppStrings) -> String {
        switch self {
        case .microphone: return strings.permissionMicExplanation
        case .speech: return strings.permissionSpeechExplanation
        case .notifications: return strings.permissionNotificationsExplanation
        case .calendar: return strings.permissionCalendarExplanation
        }
    }
}

// MARK: - Speech recognizer user messages

struct SpeechServiceMessages: Equatable {
    let speechNotAvailable: String
    let micDeniedSettings: String
    let micDenied: String
    let micUnavailable: String
    let unsupportedLocale: String
    let localeUnavailable: String
    let micUseFailed: String
    let micInputUnavailable: String
    let audioStartFailed: String
    let nothingToStop: String
    let speechDeniedSettings: String
    let speechRestricted: String
    let speechNotDetermined: String
    let speechNotAllowed: String
    let noSpeechDetected: String
    let recognitionCanceled: String
    let recognitionFailedFormat: String
    let recognitionStopped: String
    let interrupted: String

    static let english = SpeechServiceMessages(
        speechNotAvailable: "Speech recognition is not available.",
        micDeniedSettings: "Microphone access was denied. Enable it in Settings → Privacy → Microphone.",
        micDenied: "Microphone access is denied. Enable it in Settings → Privacy → Microphone.",
        micUnavailable: "Microphone is not available.",
        unsupportedLocale: "Speech recognition isn’t supported for “%@”. Try another language.",
        localeUnavailable: "Speech recognition isn’t available for “%@” on this device right now. Try English, check your network, or try again later.",
        micUseFailed: "Could not use the microphone: %@",
        micInputUnavailable: "Microphone input isn’t available on this device.",
        audioStartFailed: "Could not start audio: %@",
        nothingToStop: "Nothing to stop — start listening first.",
        speechDeniedSettings: "Speech recognition is turned off. Enable it in Settings → Privacy → Speech Recognition.",
        speechRestricted: "Speech recognition is restricted on this device.",
        speechNotDetermined: "Speech recognition permission is required.",
        speechNotAllowed: "Speech recognition isn’t allowed.",
        noSpeechDetected: "No speech was detected. Try again and speak a bit closer to the microphone.",
        recognitionCanceled: "Recognition was canceled.",
        recognitionFailedFormat: "Speech recognition failed: %@",
        recognitionStopped: "Recognition stopped.",
        interrupted: "Interrupted."
    )

    static let chineseSimplified = SpeechServiceMessages(
        speechNotAvailable: "语音识别不可用。",
        micDeniedSettings: "麦克风权限被拒绝。请在 设置 → 隐私 → 麦克风中开启。",
        micDenied: "麦克风权限被拒绝。请在 设置 → 隐私 → 麦克风中开启。",
        micUnavailable: "麦克风不可用。",
        unsupportedLocale: "不支持「%@」的语音识别，请尝试其他语言。",
        localeUnavailable: "当前设备暂时无法使用「%@」的语音识别。可尝试英语、检查网络或稍后再试。",
        micUseFailed: "无法使用麦克风：%@",
        micInputUnavailable: "此设备没有可用的麦克风输入。",
        audioStartFailed: "无法启动音频：%@",
        nothingToStop: "尚未开始聆听，无需停止。",
        speechDeniedSettings: "语音识别已关闭。请在 设置 → 隐私 → 语音识别中开启。",
        speechRestricted: "此设备限制使用语音识别。",
        speechNotDetermined: "需要语音识别权限。",
        speechNotAllowed: "不允许使用语音识别。",
        noSpeechDetected: "未检测到语音，请靠近麦克风再试。",
        recognitionCanceled: "识别已取消。",
        recognitionFailedFormat: "语音识别失败：%@",
        recognitionStopped: "识别已停止。",
        interrupted: "已中断。"
    )
}

extension PermissionStatus {
    func label(strings: AppStrings) -> String {
        switch self {
        case .notDetermined: return strings.statusNotAsked
        case .granted: return strings.statusAllowed
        case .denied: return strings.statusDenied
        case .restricted: return strings.statusRestricted
        case .provisional: return strings.statusProvisional
        case .unknown: return strings.statusUnknown
        }
    }
}
