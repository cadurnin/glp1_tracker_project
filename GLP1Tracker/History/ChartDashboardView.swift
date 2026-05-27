import SwiftUI
import Charts
import SwiftData

enum TimeRange: String, CaseIterable {
    case week = "7D"
    case month = "30D"
    case threeMonths = "3M"

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        }
    }
}

struct ChartDashboardView: View {
    @Query(sort: \DailyCheckIn.date) private var allCheckIns: [DailyCheckIn]
    @AppStorage("useKg") private var useKg = true
    @AppStorage("useLitres") private var useLitres = true

    @State private var range: TimeRange = .week

    private var checkIns: [DailyCheckIn] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date())!
        return allCheckIns.filter { $0.date >= cutoff }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Range", selection: $range) {
                    ForEach(TimeRange.allCases, id: \.self) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if checkIns.isEmpty {
                    ContentUnavailableView("No data", systemImage: "chart.xyaxis.line",
                                          description: Text("Complete some check-ins to see charts."))
                        .padding(.top, 60)
                } else {
                    weightChart
                    scoreChart
                    waterChart
                    symptomBarChart
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: Weight

    private var weightChart: some View {
        let data = checkIns.compactMap { c -> (Date, Double)? in
            guard let w = c.weightKg else { return nil }
            return (c.date, useKg ? w : w / 0.453592)
        }

        return chartCard(title: "Weight", unit: useKg ? "kg" : "lbs") {
            Chart(data, id: \.0) { item in
                LineMark(x: .value("Date", item.0, unit: .day),
                         y: .value("Weight", item.1))
                .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", item.0, unit: .day),
                          y: .value("Weight", item.1))
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: max(1, range.days / 7))) }
        }
    }

    // MARK: Score

    private var scoreChart: some View {
        chartCard(title: "Overall Score", unit: "/10") {
            Chart(checkIns) { c in
                BarMark(x: .value("Date", c.date, unit: .day),
                        y: .value("Score", c.overallScore))
                .foregroundStyle(scoreColor(c.overallScore))
            }
            .chartYScale(domain: 0...10)
        }
    }

    // MARK: Water

    private var waterChart: some View {
        let data = checkIns.compactMap { c -> (Date, Double)? in
            guard let w = c.waterLitres else { return nil }
            return (c.date, useLitres ? w : w / 0.0295735)
        }

        return chartCard(title: "Water Intake", unit: useLitres ? "L" : "oz") {
            Chart(data, id: \.0) { item in
                BarMark(x: .value("Date", item.0, unit: .day),
                        y: .value("Water", item.1))
                .foregroundStyle(Color.cyan.gradient)
            }
        }
    }

    // MARK: Symptom bar

    private var symptomBarChart: some View {
        let counts = Dictionary(grouping: checkIns.flatMap { $0.symptoms.filter { $0.present } },
                                by: { $0.symptomId })
            .map { (id: $0.key, count: $0.value.count) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
            .prefix(8)

        return chartCard(title: "Top Symptoms", unit: "occurrences") {
            Chart(counts, id: \.id) { item in
                let name = SymptomList.all.first(where: { $0.id == item.id })?.name ?? item.id
                BarMark(x: .value("Count", item.count),
                        y: .value("Symptom", name))
                .foregroundStyle(Color.accentColor.gradient)
            }
        }
    }

    // MARK: Helpers

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 1...3: return .red
        case 4...6: return .orange
        default: return .green
        }
    }

    @ViewBuilder
    private func chartCard<C: View>(title: String, unit: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content()
                .frame(height: 180)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
