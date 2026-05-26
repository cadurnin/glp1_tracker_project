import SwiftUI
import Charts
import SwiftData

enum TimeRange: String, CaseIterable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case allTime = "All"

    func startDate(from end: Date = Date()) -> Date {
        let cal = Calendar.current
        switch self {
        case .week:        return cal.date(byAdding: .day,   value: -7,  to: end)!
        case .month:       return cal.date(byAdding: .month, value: -1,  to: end)!
        case .threeMonths: return cal.date(byAdding: .month, value: -3,  to: end)!
        case .allTime:     return .distantPast
        }
    }
}

struct ChartDashboardView: View {
    let checkIns: [DailyCheckIn]
    let snapshots: [HealthSnapshot]

    @State private var range: TimeRange = .month

    private var filteredCheckIns: [DailyCheckIn] {
        let start = range.startDate()
        return checkIns.filter { $0.date >= start }.sorted { $0.date < $1.date }
    }

    private var filteredSnapshots: [HealthSnapshot] {
        let start = range.startDate()
        return snapshots.filter { $0.date >= start }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Picker("Range", selection: $range) {
                ForEach(TimeRange.allCases, id: \.self) { r in
                    Text(r.rawValue).tag(r)
                }
            }
            .pickerStyle(.segmented)

            if filteredCheckIns.isEmpty {
                ContentUnavailableView("No data for this range", systemImage: "chart.xyaxis.line")
                    .padding(.top, 40)
            } else {
                weightChart
                overallScoreChart
                waterChart
                sleepChart
                heartRateChart
                symptomHeatmap
            }
        }
    }

    // MARK: Weight

    @ViewBuilder
    private var weightChart: some View {
        let data = filteredCheckIns.compactMap { c -> (Date, Double)? in
            guard let w = c.weightKg else { return nil }
            return (c.date, w)
        }
        if !data.isEmpty {
            chartSection("Weight (kg)", systemImage: "scalemass") {
                Chart {
                    ForEach(data, id: \.0) { date, weight in
                        LineMark(x: .value("Date", date), y: .value("kg", weight))
                            .foregroundStyle(Color.blue)
                        AreaMark(x: .value("Date", date), y: .value("kg", weight))
                            .foregroundStyle(Color.blue.opacity(0.08))
                    }
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
            }
        }
    }

    // MARK: Overall score

    private var overallScoreChart: some View {
        chartSection("Overall Feel Score", systemImage: "heart.fill") {
            Chart {
                ForEach(filteredCheckIns) { c in
                    LineMark(x: .value("Date", c.date), y: .value("Score", c.overallScore))
                        .foregroundStyle(Color.pink)
                    PointMark(x: .value("Date", c.date), y: .value("Score", c.overallScore))
                        .foregroundStyle(Color.pink)
                }
            }
            .chartYScale(domain: 1...10)
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        }
    }

    // MARK: Water

    @ViewBuilder
    private var waterChart: some View {
        let data = filteredCheckIns.compactMap { c -> (Date, Double)? in
            guard let w = c.waterLitres else { return nil }
            return (c.date, w)
        }
        if !data.isEmpty {
            chartSection("Water Intake (L)", systemImage: "drop.fill") {
                Chart {
                    ForEach(data, id: \.0) { date, litres in
                        BarMark(x: .value("Date", date), y: .value("Litres", litres))
                            .foregroundStyle(Color.cyan)
                    }
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
            }
        }
    }

    // MARK: Sleep

    @ViewBuilder
    private var sleepChart: some View {
        let data = filteredSnapshots.compactMap { s -> (Date, Double)? in
            guard let h = s.sleepHours else { return nil }
            return (s.date, h)
        }
        if !data.isEmpty {
            chartSection("Sleep (hrs)", systemImage: "bed.double.fill") {
                Chart {
                    ForEach(data, id: \.0) { date, hours in
                        BarMark(x: .value("Date", date), y: .value("Hours", hours))
                            .foregroundStyle(Color.indigo)
                    }
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
            }
        }
    }

    // MARK: Heart rate

    @ViewBuilder
    private var heartRateChart: some View {
        let data = filteredSnapshots.compactMap { s -> (Date, Double)? in
            guard let hr = s.restingHeartRate else { return nil }
            return (s.date, hr)
        }
        if !data.isEmpty {
            chartSection("Resting Heart Rate (bpm)", systemImage: "waveform.path.ecg") {
                Chart {
                    ForEach(data, id: \.0) { date, bpm in
                        LineMark(x: .value("Date", date), y: .value("bpm", bpm))
                            .foregroundStyle(Color.red)
                    }
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
            }
        }
    }

    // MARK: Symptom heatmap

    private var symptomHeatmap: some View {
        let topSymptoms = topSymptomsByFrequency(in: filteredCheckIns, limit: 8)
        return Group {
            if !topSymptoms.isEmpty {
                chartSection("Symptom Frequency", systemImage: "chart.bar.fill") {
                    Chart {
                        ForEach(topSymptoms, id: \.id) { symptom in
                            let count = filteredCheckIns.filter { day in
                                day.symptoms.contains { $0.symptomId == symptom.id && $0.present }
                            }.count
                            BarMark(
                                x: .value("Count", count),
                                y: .value("Symptom", symptom.name)
                            )
                            .foregroundStyle(Color.accentColor)
                        }
                    }
                    .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }
                    .frame(height: CGFloat(topSymptoms.count) * 36)
                }
            }
        }
    }

    private func topSymptomsByFrequency(in checkIns: [DailyCheckIn], limit: Int) -> [Symptom] {
        var counts: [String: Int] = [:]
        for c in checkIns {
            for s in c.symptoms where s.present {
                counts[s.symptomId, default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .compactMap { SymptomList.symptom(for: $0.key) }
    }

    @ViewBuilder
    private func chartSection<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            content()
                .frame(height: 160)
                .padding(.vertical, 4)
        }
        Divider()
    }
}
