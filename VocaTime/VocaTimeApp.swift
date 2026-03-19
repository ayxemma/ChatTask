import SwiftUI

@main
struct VocaTimeApp: App {
    @State private var permissionService = PermissionService()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
                    .environment(permissionService)
            }
        }
    }
}
