import Foundation

enum TrendDirection {
    case improving, worsening, stable
}

struct OutlierInsight: Identifiable {
    let id = UUID()
    let metric: String
    let current: String
    let normalRange: String
    let trend: TrendDirection
    let detail: String
}

struct OutlierDetector {
    // Minimum data points before computing baseline
    private static let minimumDays = 7
    private static let zThreshold: Double = 1.5

    func analyze(snapshots: [HealthSnapshot]) -> [OutlierInsight]? {
        guard snapshots.count >= Self.minimumDays else { return nil }

        let sorted = snapshots.sorted { $0.date < $1.date }
        var insights: [OutlierInsight] = []

        if let insight = checkHR(sorted) { insights.append(insight) }
        if let insight = checkSleep(sorted) { insights.append(insight) }
        if let insight = checkWater(sorted) { insights.append(insight) }
        if let insight = checkWeightVelocity(sorted) { insights.append(insight) }

        return insights
    }

    // MARK: Individual metric checks

    private func checkHR(_ snapshots: [HealthSnapshot]) -> OutlierInsight? {
        let values = snapshots.compactMap(\.restingHeartRate)
        guard values.count >= Self.minimumDays, let latest = values.last else { return nil }
        let (mean, sd) = stats(values.dropLast())
        guard sd > 0, abs(latest - mean) > Self.zThreshold * sd else { return nil }
        let lo = Int(mean - sd), hi = Int(mean + sd)
        let trend: TrendDirection = latest > mean ? .worsening : .improving
        return OutlierInsight(
            metric: "Resting Heart Rate",
            current: "\(Int(latest)) bpm",
            normalRange: "\(lo)–\(hi) bpm",
            trend: trend,
            detail: "Your resting heart rate today (\(Int(latest)) bpm) is \(latest > mean ? "higher" : "lower") than your usual range (\(lo)–\(hi) bpm)"
        )
    }

    private func checkSleep(_ snapshots: [HealthSnapshot]) -> OutlierInsight? {
        let values = snapshots.compactMap(\.sleepHours)
        guard values.count >= Self.minimumDays, let latest = values.last else { return nil }
        let (mean, sd) = stats(values.dropLast())
        guard sd > 0, abs(latest - mean) > Self.zThreshold * sd else { return nil }
        let lo = String(format: "%.1f", mean - sd), hi = String(format: "%.1f", mean + sd)
        let trend: TrendDirection = latest < mean ? .worsening : .improving
        return OutlierInsight(
            metric: "Sleep",
            current: String(format: "%.1f hrs", latest),
            normalRange: "\(lo)–\(hi) hrs",
            trend: trend,
            detail: String(format: "You slept %.1f hrs last night — \(latest < mean ? "less" : "more") than your usual \(lo)–\(hi) hrs", latest)
        )
    }

    private func checkWater(_ snapshots: [HealthSnapshot]) -> OutlierInsight? {
        let values = snapshots.compactMap(\.waterLitres)
        guard values.count >= Self.minimumDays, let latest = values.last else { return nil }
        let (mean, sd) = stats(values.dropLast())
        guard sd > 0, abs(latest - mean) > Self.zThreshold * sd else { return nil }
        let lo = String(format: "%.1f", mean - sd), hi = String(format: "%.1f", mean + sd)
        let trend: TrendDirection = latest < mean ? .worsening : .improving
        return OutlierInsight(
            metric: "Water Intake",
            current: String(format: "%.1f L", latest),
            normalRange: "\(lo)–\(hi) L",
            trend: trend,
            detail: String(format: "Your water intake today (%.1f L) is \(latest < mean ? "lower" : "higher") than your usual range (\(lo)–\(hi) L)", latest)
        )
    }

    private func checkWeightVelocity(_ snapshots: [HealthSnapshot]) -> OutlierInsight? {
        let weighted = snapshots.compactMap { s -> (Date, Double)? in
            guard let w = s.weightKg else { return nil }
            return (s.date, w)
        }
        guard weighted.count >= 8 else { return nil }

        // Compute weekly velocities
        var velocities: [Double] = []
        for i in 7..<weighted.count {
            let days = weighted[i].0.timeIntervalSince(weighted[i - 7].0) / 86400
            guard days > 0 else { continue }
            let delta = weighted[i].1 - weighted[i - 7].1
            velocities.append(delta / days * 7)
        }
        guard velocities.count >= 2, let latestV = velocities.last else { return nil }
        let (mean, sd) = stats(velocities.dropLast())
        guard sd > 0, abs(latestV - mean) > Self.zThreshold * sd else { return nil }
        let trend: TrendDirection = latestV < mean ? .worsening : .stable
        return OutlierInsight(
            metric: "Weight Change Rate",
            current: String(format: "%.2f kg/wk", latestV),
            normalRange: String(format: "%.2f–%.2f kg/wk", mean - sd, mean + sd),
            trend: trend,
            detail: String(format: "Your weight is changing at %.2f kg/week — outside your usual rate", latestV)
        )
    }

    // MARK: Stats helpers

    private func stats<C: Collection>(_ values: C) -> (mean: Double, sd: Double) where C.Element == Double {
        let arr = Array(values)
        guard !arr.isEmpty else { return (0, 0) }
        let mean = arr.reduce(0, +) / Double(arr.count)
        let variance = arr.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(arr.count)
        return (mean, variance.squareRoot())
    }
}
