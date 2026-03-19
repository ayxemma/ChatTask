# VocaTime Tasks for Cursor

## Project Goal
Build VocaTime, an iOS app that converts voice into reminders and calendar events.

---

## Working Rules
- SwiftUI only
- Native frameworks only
- Keep code simple
- Keep app always runnable
- Do not over-engineer

---

## Target Architecture

- `VocaTimeApp.swift`

### Views
- `HomeView.swift`
- `RecordButtonView.swift`
- `ConfirmationView.swift`
- `PermissionsView.swift`

### ViewModels
- `VoiceCommandViewModel.swift`

### Services
- `SpeechRecognizerService.swift`
- `IntentParserService.swift`
- `ReminderService.swift`
- `CalendarService.swift`
- `PermissionService.swift`

### Models
- `ParsedCommand.swift`
- `ReminderItem.swift`
- `CalendarEventItem.swift`

### Utilities
- `DateParser.swift`
- `AppError.swift`

---

## Phase 1 — UI Skeleton

### Tasks
- Build HomeView
- Add:
  - title
  - subtitle
  - microphone button
  - text display
  - action button
- Add simple state:
  - idle
  - listening
  - processing
  - success
  - error

### Acceptance
- App runs
- UI works
- No crashes

---

## Phase 2 — Permissions

### Tasks
- Implement PermissionService
- Handle:
  - microphone
  - speech
  - notifications
  - calendar
- Show permission status UI

### Acceptance
- Permissions visible
- No silent failures

---

## Phase 3 — Speech-to-Text

### Tasks
- Implement SpeechRecognizerService
- Start/stop recording
- Show live text

### Acceptance
- Voice → text works

---

## Phase 4 — Parsing (MVP)

### Tasks
- Implement IntentParserService
- Support:
  - "in X minutes"
  - "at 3 PM"
  - "today"
  - "tomorrow"
- Build DateParser

### Acceptance
- Basic commands parsed correctly

---

## Phase 5 — Reminder

### Tasks
- Implement ReminderService
- Schedule local notifications

### Acceptance
- Reminder fires correctly

---

## Phase 6 — Calendar

### Tasks
- Implement CalendarService
- Save event via EventKit

### Acceptance
- Event appears in iOS Calendar

---

## Phase 7 — Confirmation

### Tasks
- Show parsed result
- Allow edit
- Confirm before saving

---

## Phase 8 — History

### Tasks
- Store last 10 commands
- Show simple list

---

## Phase 9 — Polish

### Tasks
- Improve UI
- Add loading states
- Handle all errors

---

## Phase 10 — AI Parsing (Optional)

### Tasks
- Add optional AI parser
- Keep fallback logic

---

## Definition of Done

User can:
1. Speak
2. See text
3. Confirm
4. Get reminder or calendar event

---

## Cursor Execution Rules

1. Start with Phase 1 + Phase 2 only
2. After completion:
   - summarize work
   - show file tree
   - stop
3. Keep code clean and simple
4. Prefer working features over perfection

---

## First Task

Implement:
- Phase 1 (UI)
- Phase 2 (Permissions)

Then stop and report.