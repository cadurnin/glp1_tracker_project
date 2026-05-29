import SwiftUI
import Charts

struct HeartRateCheckInCard: View {
    let readings: [DailyHeartRate]   // last 7 days for the chart
    let stats: HeartRateStats

    var body: some View {
        if !stats.hasEnoughData {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Label("Resting Heart Rate", systemImage: "heart.fill")
                    .font(.headline)

                HStack(spacing: 24) {
                    statColumn(label: "7-day avg", value: stats.sevenDayAverage)
                    statColumn(label: "90-day baseline", value: stats.ninetyDayMean)
                }

                Chart {
                    ForEach(readings, id: \.date) { reading in
                        BarMark(
                            x: .value("Day", reading.date, unit: .day),
                            y: .value("BPM", reading.bpm)
                        )
                        .foregroundStyle(isOutlier(reading) ? Color.red : Color.blue)
                    }

                    RuleMark(y: .value("Upper", stats.upperThreshold))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.orange)

                    RuleMark(y: .value("Lower", stats.lowerThreshold))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.orange)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .frame(height: 110)

                if !stats.outliers.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(stats.outliers, id: \.date) { outlier in
                            HStack {
                                Text(outlier.date, format: .dateTime.month(.abbreviated).day().year())
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(outlier.bpm)) bpm")
                                    .font(.subheadline)
                                if outlier.bpm > stats.upperThreshold {
                                    Text("↑ Above normal")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                } else {
                                    Text("↓ Below normal")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func isOutlier(_ reading: DailyHeartRate) -> Bool {
        stats.outliers.contains { Calendar.current.isDate($0.date, inSameDayAs: reading.date) }
    }

    private func statColumn(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(Int(value)) bpm")
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let readings: [DailyHeartRate] = (0..<7).map { offset in
        let date = calendar.date(byAdding: .day, value: offset - 6, to: today)!
        let bpm: Double = [62, 65, 98, 63, 61, 66, 64][offset]
        return DailyHeartRate(date: date, bpm: bpm)
    }
    let allReadings = readings + (0..<83).map { offset in
        let date = calendar.date(byAdding: .day, value: offset - 89, to: today)!
        return DailyHeartRate(date: date, bpm: 63)
    }
    let stats = HeartRateAnalyzer.analyze(allReadings.sorted { $0.date < $1.date })
    return HeartRateCheckInCard(readings: readings, stats: stats)
        .padding()
}
