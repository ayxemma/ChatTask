import SwiftUI

struct RootTabView: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        let s = appSettings.language.strings
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(s.homeTab, systemImage: "house.fill")
            }

            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label(s.calendarTab, systemImage: "calendar")
            }
        }
    }
}
