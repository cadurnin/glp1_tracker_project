import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query(sort: \HealthSnapshot.date, order: .reverse) private var snapshots: [HealthSnapshot]

    @State private var showCharts = true

    var body: some View {
        NavigationStack {
            Group {
                if showCharts {
                    ScrollView {
                        ChartDashboardView(checkIns: checkIns, snapshots: snapshots)
                            .padding()
                    }
                } else {
                    ScrollView {
                        CheckInListView(checkIns: checkIns)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker("View", selection: $showCharts) {
                        Label("Charts", systemImage: "chart.xyaxis.line").tag(true)
                        Label("List", systemImage: "list.bullet").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
        }
    }
}
