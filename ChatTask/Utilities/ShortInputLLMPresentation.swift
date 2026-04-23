import Foundation

// MARK: - Short-input heuristic (word vs dense phrase)

/// Detects *clearly* short task phrases for Option B (LLM title/notes post-processing only).
/// Not language-aware NLP — intentionally lightweight.
enum ShortInputHeuristic {
    /// “Under about 8 word-like units” for space‑separated text: short when under 8 words.
    private static let maxWordCount = 15
    /// CJK / no spaces: one character ≈ one unit; conservative ceiling for a compact line.
    private static let maxCharacterCountDense = 20

    static func isShortTaskPhrase(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return true }

        let words = t.split { $0.isWhitespace || $0.isNewline }.filter { !$0.isEmpty }
        if words.count >= 2 {
            return words.count < maxWordCount
        }
        // Single token: typical for CJK or one English word; use length as proxy.
        return t.count < maxCharacterCountDense
    }
}

// MARK: - Option B: LLM presentation only (no second parse)

/// Post-processes **LLM** `ParsedCommand` for short user inputs: keep scheduling/action from
/// the model, but use the user’s full phrase as `title` and `notes = nil`.
enum ShortInputLLMPresentation {

    static func applyOptionB(userInput: String, command: ParsedCommand) -> ParsedCommand {
        guard command.parserSource == .llm else { return command }
        switch command.actionType {
        case .deleteTask, .rescheduleTask, .appendToTask, .updateTaskTitle:
            return command
        default:
            break
        }
        guard ShortInputHeuristic.isShortTaskPhrase(userInput) else { return command }

        var c = command
        let phrase = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !phrase.isEmpty {
            c.title = phrase
        }
        c.notes = nil
        return c
    }
}
