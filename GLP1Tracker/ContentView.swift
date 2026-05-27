import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CheckInWizardView()
                .tabItem { Label("Check In", systemImage: "checkmark.circle") }
                .tag(0)

            HistoryView()
                .tabItem { Label("History", systemImage: "chart.xyaxis.line") }
                .tag(1)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "lightbulb") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDestination)) { note in
            let destination = note.userInfo?["destination"] as? String
            selectedTab = destination == "weeklyCheckIn" ? 3 : 0
        }
    }
}
