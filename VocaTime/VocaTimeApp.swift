import SwiftData
import SwiftUI

@main
struct VocaTimeApp: App {
    @State private var permissionService = PermissionService()
    @State private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(permissionService)
                .environment(appSettings)
                .environment(\.locale, appSettings.language.uiLocale)
        }
        .modelContainer(for: TaskItem.self)
    }
}
