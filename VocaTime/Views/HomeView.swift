import SwiftUI

struct HomeView: View {
    @Environment(PermissionService.self) private var permissionService
    @State private var viewModel = VoiceCommandViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("VocaTime")
                        .font(.largeTitle.weight(.semibold))
                    Text("Speak → Understand → Schedule → Remind")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                statusStrip

                RecordButtonView(
                    isListening: viewModel.flowState == .listening,
                    isEnabled: viewModel.flowState != .processing,
                    action: { viewModel.microphoneTapped() }
                )
                .padding(.vertical, 8)

                flowStateLabel

                textCard

                Button(action: { viewModel.primaryActionTapped() }) {
                    Text(primaryButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)

                NavigationLink {
                    PermissionsView()
                } label: {
                    Label("Permission status", systemImage: "lock.shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .task {
            await permissionService.refreshAll()
        }
    }

    @ViewBuilder
    private var statusStrip: some View {
        let denied = PermissionKind.allCases.filter {
            permissionService.status(for: $0) == .denied
        }
        if !denied.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Some permissions are denied: \(denied.map(\.title).joined(separator: ", "))")
                    .font(.footnote)
                Text("Open Permission status to request access or fix in Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private var flowStateLabel: some View {
        Text(stateDescription)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(stateColor)
    }

    private var textCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcript")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(displayText)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(displayText == placeholderText ? .secondary : .primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var placeholderText: String {
        "Your words will appear here after you speak."
    }

    private var displayText: String {
        if let err = viewModel.errorMessage, viewModel.flowState == .error {
            return err
        }
        if viewModel.displayedText.isEmpty {
            return placeholderText
        }
        return viewModel.displayedText
    }

    private var primaryButtonTitle: String {
        switch viewModel.flowState {
        case .success: return "Done"
        case .error: return "Dismiss"
        default: return "Continue"
        }
    }

    private var stateDescription: String {
        switch viewModel.flowState {
        case .idle: return "Idle — tap the microphone to begin"
        case .listening: return "Listening… tap again when finished"
        case .processing: return "Processing…"
        case .success: return "Success"
        case .error: return "Something went wrong"
        }
    }

    private var stateColor: Color {
        switch viewModel.flowState {
        case .idle: return .secondary
        case .listening: return .red
        case .processing: return .orange
        case .success: return .green
        case .error: return .red
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(PermissionService())
    }
}
