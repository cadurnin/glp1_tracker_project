import Foundation

struct PatternInsight: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let symbolName: String
}

enum SymptomPatternAnalyzer {
    /// Analyzes symptom patterns across check-ins to detect frequency, severity trends, new symptoms, and injection-day correlations.
    /// Requires at least 7 check-ins; returns empty array if below threshold.
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records to analyze.
    /// - Returns: Array of PatternInsight describing detected symptom patterns and trends.
    static func analyze(checkIns: [DailyCheckIn]) -> [PatternInsight] {
        guard checkIns.count >= 7 else { return [] }
        var insights: [PatternInsight] = []

        insights += frequencyInsights(checkIns: checkIns)
        insights += newSymptomInsights(checkIns: checkIns)
        insights += severityTrendInsights(checkIns: checkIns)
        insights += cycleDayInsights(checkIns: checkIns)

        return insights
    }

    // MARK: Frequency

    /// Detects symptoms appearing in ≥70% of the last 7 check-ins.
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records to analyze.
    /// - Returns: Array of PatternInsight for frequently reported symptoms.
    private static func frequencyInsights(checkIns: [DailyCheckIn]) -> [PatternInsight] {
        let recent = Array(checkIns.sorted { $0.date > $1.date }.prefix(7))
        let totalDays = Double(recent.count)

        var insights: [PatternInsight] = []
        for symptom in SymptomList.all {
            let count = Double(recent.filter { c in c.symptoms.contains { $0.symptomId == symptom.id && $0.present } }.count)
            let rate = count / totalDays
            if rate >= 0.7 {
                insights.append(PatternInsight(
                    title: "Frequent: \(symptom.name)",
                    message: "\(symptom.name) has appeared in \(Int(rate * 100))% of your recent check-ins.",
                    symbolName: "repeat.circle.fill"
                ))
            }
        }
        return insights
    }

    // MARK: New symptom

    /// Detects symptoms that appeared in the last 3 check-ins but not in earlier ones.
    /// Requires at least 8 check-ins; returns empty array otherwise.
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records to analyze.
    /// - Returns: Array of PatternInsight for newly reported symptoms.
    private static func newSymptomInsights(checkIns: [DailyCheckIn]) -> [PatternInsight] {
        let sorted = checkIns.sorted { $0.date < $1.date }
        guard sorted.count >= 8 else { return [] }
        let recent = Array(sorted.suffix(3))
        let previous = Array(sorted.dropLast(3))

        let previousIds = Set(previous.flatMap { $0.symptoms.filter { $0.present }.map { $0.symptomId } })
        let recentIds = Set(recent.flatMap { $0.symptoms.filter { $0.present }.map { $0.symptomId } })
        let newIds = recentIds.subtracting(previousIds)

        return newIds.compactMap { id in
            guard let symptom = SymptomList.all.first(where: { $0.id == id }) else { return nil }
            return PatternInsight(
                title: "New Symptom",
                message: "\(symptom.name) appeared recently for the first time.",
                symbolName: "exclamationmark.circle.fill"
            )
        }
    }

    // MARK: Severity trend

    /// Detects symptoms that track severity and are either worsening (recent avg > old avg + 1.0) or improving (recent avg < old avg - 1.0).
    /// Skips symptoms without severity tracking; requires at least 4 severity entries per symptom.
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records to analyze.
    /// - Returns: Array of PatternInsight for symptoms with improving or worsening trends.
    private static func severityTrendInsights(checkIns: [DailyCheckIn]) -> [PatternInsight] {
        let sorted = checkIns.sorted { $0.date < $1.date }
        var insights: [PatternInsight] = []

        for symptom in SymptomList.all where symptom.tracksSeverity {
            let severities = sorted.compactMap { c -> Double? in
                guard let entry = c.symptoms.first(where: { $0.symptomId == symptom.id }),
                      entry.present, let sev = entry.severity else { return nil }
                return Double(sev)
            }
            guard severities.count >= 4 else { continue }

            let recent = severities.suffix(3)
            let old = severities.dropLast(3)
            let recentAvg = recent.reduce(0, +) / Double(recent.count)
            let oldAvg = old.reduce(0, +) / Double(old.count)

            if recentAvg > oldAvg + 1.0 {
                insights.append(PatternInsight(
                    title: "\(symptom.name) Worsening",
                    message: "The severity of \(symptom.name) has been increasing recently.",
                    symbolName: "arrow.up.circle.fill"
                ))
            } else if recentAvg < oldAvg - 1.0 {
                insights.append(PatternInsight(
                    title: "\(symptom.name) Improving",
                    message: "The severity of \(symptom.name) appears to be improving.",
                    symbolName: "arrow.down.circle.fill"
                ))
            }
        }
        return insights
    }

    // MARK: Cycle day

    /// Detects if injection days (those with injectionLogId) have ≥3 symptoms on average, suggesting an injection-day pattern.
    /// Requires at least 3 injection-day check-ins; returns empty array otherwise.
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records to analyze.
    /// - Returns: Array with zero or one PatternInsight describing injection-day symptom correlation.
    private static func cycleDayInsights(checkIns: [DailyCheckIn]) -> [PatternInsight] {
        let injectionDayCheckIns = checkIns.filter { $0.injectionLogId != nil }
        guard injectionDayCheckIns.count >= 3 else { return [] }

        let symptomCounts = injectionDayCheckIns.map {
            $0.symptoms.filter { $0.present }.count
        }
        let avg = Double(symptomCounts.reduce(0, +)) / Double(symptomCounts.count)

        if avg >= 3 {
            return [PatternInsight(
                title: "Injection Day Pattern",
                message: "You tend to experience more symptoms on injection days. This is common — consider timing your dose in the evening.",
                symbolName: "syringe.fill"
            )]
        }
        return []
    }
}
