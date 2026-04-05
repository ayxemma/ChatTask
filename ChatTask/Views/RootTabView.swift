import SwiftUI

struct RootTabView: View {
    @Environment(\.appUILanguage) private var appUILanguage

    var body: some View {
        let s = appUILanguage.strings
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
