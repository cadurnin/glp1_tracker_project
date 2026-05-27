import SwiftUI

struct HistoryView: View {
    @State private var showCharts = false

    var body: some View {
        NavigationStack {
            Group {
                if showCharts {
                    ChartDashboardView()
                } else {
                    CheckInListView()
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("View", selection: $showCharts) {
                        Image(systemName: "list.bullet").tag(false)
                        Image(systemName: "chart.xyaxis.line").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}
