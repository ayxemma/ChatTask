# VocaTime iOS App

## Overview
VocaTime is an iOS app that converts natural voice commands into reminders and calendar events.

Core idea:
Speak → Understand → Schedule → Remind

Examples:
- "Remind me in 5 minutes to check the oven"
- "Today at 3 PM call the doctor"
- "Tomorrow morning bring Ari's shoes"

---

## Product Principles
1. The app should feel effortless and fast.
2. Voice is the primary input method.
3. Users should not need to manually type anything.
4. Every interaction should reduce friction vs existing tools.
5. Prefer simplicity over feature completeness.

---

## Engineering Principles
1. Build MVP first, then iterate.
2. Keep the app compiling at every step.
3. Use native Apple frameworks when possible.
4. Avoid over-engineering and unnecessary abstraction.
5. Prefer small, testable components.
6. Fail gracefully and visibly.

---

## Tech Stack
- Language: Swift
- UI: SwiftUI
- Speech-to-text: Apple Speech Framework
- Calendar: EventKit
- Notifications: UserNotifications

---

## Architecture Guidelines

### High-Level Layers
- Views (UI)
- ViewModels (state + logic orchestration)
- Services (external system interactions)
- Models (data structures)
- Utilities (helpers)

---

### Folder Structure
- `Views/`
- `ViewModels/`
- `Services/`
- `Models/`
- `Utilities/`

---

## Core Flow
1. User taps microphone
2. App records voice
3. Speech is converted to text
4. Text is parsed into structured command
5. User confirms or edits result
6. App creates:
   - reminder (notification), or
   - calendar event
7. App shows success feedback

---

## Parsing Strategy
Start simple, then improve:

### Stage 1 (MVP)
- Rule-based parsing
- Simple pattern matching
- Basic time extraction

### Stage 2
- Improve heuristics
- Handle ambiguity

### Stage 3 (Optional)
- Introduce AI/LLM parsing

---

## UX Guidelines
- Minimal UI
- Clear primary action
- No clutter
- Calm, Apple-style design
- Immediate feedback after actions

---

## Error Handling Philosophy
- Never fail silently
- Always show user-readable errors
- Provide actionable next steps

---

## Security & Privacy
- Do not store user audio permanently
- Do not hardcode API keys
- Request permissions only when needed
- Respect user privacy (especially calendar data)

---

## Definition of Success (MVP)
The app is successful if a user can:
1. Open app
2. Speak a command
3. See it transcribed
4. See it parsed correctly
5. Confirm it
6. Get a reminder or calendar event created

---

## Cursor Operating Instructions

Follow `VOCATIME_TASKS.md` strictly.

### Rules:
1. Implement tasks phase by phase.
2. Do NOT skip phases.
3. Keep the app buildable at all times.
4. After each phase:
   - summarize changes
   - list files modified
   - mention blockers
5. Prefer working code over explanation.

---

## First Execution Step
Start with Phase 1 and Phase 2 from `VOCATIME_TASKS.md`.

Stop after completion and report progress.