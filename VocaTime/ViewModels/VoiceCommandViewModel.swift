import Foundation

enum VoiceFlowState: Equatable {
    case idle
    case listening
    case processing
    case success
    case error
}

@Observable
final class VoiceCommandViewModel {
    var flowState: VoiceFlowState = .idle
    var displayedText: String = ""
    var errorMessage: String?

    /// Phase 1: simulates listen → process → sample transcript (real speech comes in Phase 3).
    func microphoneTapped() {
        errorMessage = nil
        switch flowState {
        case .idle:
            flowState = .listening
            displayedText = ""
        case .listening:
            flowState = .processing
            Task { await simulateTranscription() }
        case .processing:
            break
        case .success, .error:
            flowState = .listening
            displayedText = ""
        }
    }

    func primaryActionTapped() {
        errorMessage = nil
        switch flowState {
        case .success, .error:
            reset()
        case .idle:
            errorMessage = "Tap the microphone to speak first."
            flowState = .error
        case .listening:
            errorMessage = "Tap the microphone again when you’re done speaking."
            flowState = .error
        case .processing:
            errorMessage = "Please wait until processing finishes."
            flowState = .error
        }
    }

    func reset() {
        flowState = .idle
        displayedText = ""
        errorMessage = nil
    }

    private func simulateTranscription() async {
        try? await Task.sleep(nanoseconds: 900_000_000)
        await MainActor.run {
            flowState = .success
            displayedText = "Remind me in 5 minutes to check the oven"
        }
    }
}
