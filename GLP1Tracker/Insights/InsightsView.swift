import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query(sort: \HealthSnapshot.date, order: .reverse) private var snapshots: [HealthSnapshot]
    @Query(sort: \InjectionLog.date, order: .reverse) private var injectionLogs: [InjectionLog]

    private let minimumDays = 7

    private var patternInsights: [PatternInsight] {
        SymptomPatternAnalyzer().analyze(checkIns: checkIns, injectionLogs: injectionLogs)
    }

    private var outlierInsights: [OutlierInsight]? {
        OutlierDetector().analyze(snapshots: snapshots)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if checkIns.count < minimumDays {
                        buildingBaselineView
                    } else {
                        if let outliers = outlierInsights, !outliers.isEmpty {
                            section("Health Outliers", systemImage: "waveform.path.ecg") {
                                ForEach(outliers) { insight in
                                    OutlierCard(insight: insight)
                                }
                            }
                        }

                        let newPatterns = patternInsights.filter(\.isNew)
                        let otherPatterns = patternInsights.filter { !$0.isNew }

                        if !newPatterns.isEmpty {
                            section("New This Week", systemImage: "sparkles") {
                                ForEach(newPatterns) { insight in
                                    PatternCard(insight: insight, accent: .orange)
                                }
                            }
                        }

                        if !otherPatterns.isEmpty {
                            section("Symptom Patterns", systemImage: "chart.bar.fill") {
                                ForEach(otherPatterns) { insight in
                                    PatternCard(insight: insight, accent: Color.accentColor)
                                }
                            }
                        }

                        if patternInsights.isEmpty && (outlierInsights ?? []).isEmpty {
                            ContentUnavailableView(
                                "No insights yet",
                                systemImage: "chart.dots.scatter",
                                description: Text("Keep logging daily and patterns will appear here.")
                            )
                            .padding(.top, 40)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }

    private var buildingBaselineView: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Building your baseline…")
                .font(.title3.bold())
            Text("Log check-ins for at least \(minimumDays) days to unlock personalized health outlier detection.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("\(checkIns.count) / \(minimumDays) days logged")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
        }
    }
}

private struct OutlierCard: View {
    let insight: OutlierInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.metric).font(.subheadline.bold())
                Spacer()
                trendIcon
            }
            Text(insight.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text("Normal: \(insight.normalRange)").font(.caption).foregroundStyle(.tertiary)
                Spacer()
                Text("Today: \(insight.current)").font(.caption.bold()).foregroundStyle(.primary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.2)))
    }

    @ViewBuilder
    private var trendIcon: some View {
        switch insight.trend {
        case .improving:
            Label("Improving", systemImage: "arrow.up.right").font(.caption).foregroundStyle(Color.green)
        case .worsening:
            Label("Elevated", systemImage: "arrow.up.right").font(.caption).foregroundStyle(Color.orange)
        case .stable:
            Label("Stable", systemImage: "minus").font(.caption).foregroundStyle(Color.gray)
        }
    }
}

private struct PatternCard: View {
    let insight: PatternInsight
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(insight.title).font(.subheadline.bold())
            Text(insight.detail).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
