import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]

    private var outliers: [OutlierInsight] {
        OutlierDetector.detect(checkIns: checkIns)
    }

    private var patterns: [PatternInsight] {
        SymptomPatternAnalyzer.analyze(checkIns: checkIns)
    }

    var body: some View {
        NavigationStack {
            Group {
                if checkIns.count < 7 {
                    buildingBaselineView
                } else {
                    insightsContent
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var buildingBaselineView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
            Text("Building your baseline…")
                .font(.title2.bold())
            Text("Complete \(max(0, 7 - checkIns.count)) more daily check-in\(7 - checkIns.count == 1 ? "" : "s") to unlock insights.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }

    private var insightsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                if outliers.isEmpty && patterns.isEmpty {
                    Text("No unusual patterns detected. Keep checking in!")
                        .foregroundStyle(.secondary)
                        .padding()
                }

                if !outliers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Outliers")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(outliers) { insight in
                            OutlierCard(insight: insight)
                        }
                    }
                }

                if !patterns.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Patterns")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(patterns) { pattern in
                            PatternCard(insight: pattern)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Outlier Card

struct OutlierCard: View {
    let insight: OutlierInsight

    var body: some View {
        HStack(spacing: 12) {
            trendIcon
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(insight.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var trendIcon: some View {
        switch insight.trend {
        case .up:
            Image(systemName: "arrow.up.circle.fill").foregroundStyle(Color.orange)
        case .down:
            Image(systemName: "arrow.down.circle.fill").foregroundStyle(Color.blue)
        case .stable:
            Image(systemName: "minus.circle.fill").foregroundStyle(Color.gray)
        }
    }
}

// MARK: - Pattern Card

struct PatternCard: View {
    let insight: PatternInsight

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.symbolName)
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
