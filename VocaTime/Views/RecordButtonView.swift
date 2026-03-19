import SwiftUI

struct RecordButtonView: View {
    let isListening: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isListening ? Color.red.opacity(0.2) : Color.accentColor.opacity(0.15))
                    .frame(width: 88, height: 88)
                Circle()
                    .strokeBorder(isListening ? Color.red : Color.accentColor, lineWidth: 3)
                    .frame(width: 88, height: 88)
                    .scaleEffect(isListening ? 1.08 : 1)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isListening)
                Image(systemName: "mic.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(isListening ? Color.red : Color.accentColor)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(isListening ? "Stop listening" : "Start listening")
    }
}

#Preview {
    RecordButtonView(isListening: false, isEnabled: true, action: {})
}
