import SwiftData
import SwiftUI

@main
struct ChatTaskApp: App {
    @State private var permissionService = PermissionService()

    init() {
        AppUILanguage.migrateLegacyUserDefaultsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(permissionService)
                .task {
                    // Request notification permission on first launch (no-op if already decided).
                    await permissionService.requestNotificationsIfNeeded()
                }
        }
        .modelContainer(for: TaskItem.self)
    }
}

private struct AppShellView: View {
    @AppStorage(AppUILanguage.storageKey) private var languageRaw: String = AppUILanguage.defaultForDevice().rawValue

    var body: some View {
        let uiLang = AppUILanguage(storageRaw: languageRaw)
        RootTabView()
            .environment(\.appUILanguage, uiLang)
            .environment(\.locale, uiLang.locale)
    }
}
