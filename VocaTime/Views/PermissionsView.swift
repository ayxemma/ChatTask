import SwiftUI
import UIKit

struct PermissionsView: View {
    @Environment(PermissionService.self) private var permissionService
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                Text("VocaTime needs these permissions to hear you, understand speech, remind you, and add calendar events. Denied items can be changed in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            Section("Status") {
                ForEach(PermissionKind.allCases) { kind in
                    PermissionRowView(kind: kind)
                }
            }

            if let message = permissionService.lastErrorMessage {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                } header: {
                    Text("Last message")
                }
            }
        }
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await permissionService.refreshAll()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
        }
    }
}

private struct PermissionRowView: View {
    @Environment(PermissionService.self) private var permissionService
    let kind: PermissionKind

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(kind.title)
                    .font(.headline)
                Spacer()
                Text(permissionService.status(for: kind).label)
                    .font(.subheadline)
                    .foregroundStyle(statusColor)
            }
            Text(kind.usageExplanation)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Request access") {
                Task {
                    await permissionService.request(kind)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(permissionService.status(for: kind) == .granted)
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch permissionService.status(for: kind) {
        case .granted, .provisional:
            return .green
        case .denied:
            return .red
        case .restricted:
            return .orange
        case .notDetermined, .unknown:
            return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        PermissionsView()
            .environment(PermissionService())
    }
}
