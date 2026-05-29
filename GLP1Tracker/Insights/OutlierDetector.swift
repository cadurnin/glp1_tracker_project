import Foundation

enum TrendDirection {
    case up, down, stable
}

struct OutlierInsight: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let trend: TrendDirection
    let date: Date
}

enum OutlierDetector {
    private static let minimumDataPoints = 7
    private static let zThreshold = 1.5

    /// Detects outliers in weight velocity, wellbeing score, and water intake using z-score analysis.
    /// Requires at least 7 check-ins; returns empty array if below threshold.
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records to analyze.
    /// - Returns: Array of OutlierInsight describing detected anomalies with trend direction and date.
    static func detect(checkIns: [DailyCheckIn]) -> [OutlierInsight] {
        guard checkIns.count >= minimumDataPoints else { return [] }
        var insights: [OutlierInsight] = []

        insights += weightOutliers(checkIns: checkIns)
        insights += scoreOutliers(checkIns: checkIns)
        insights += waterOutliers(checkIns: checkIns)
        insights += heartRateOutliers(checkIns: checkIns)

        return insights
    }

    /// Detects unusual daily weight changes using z-score analysis on velocity (kg/day).
    /// Ignores check-ins without weight data; returns empty array if insufficient data points.
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records to analyze.
    /// - Returns: Array of OutlierInsight for detected weight velocity anomalies.
    private static func weightOutliers(checkIns: [DailyCheckIn]) -> [OutlierInsight] {
        let sorted = checkIns.sorted { $0.date < $1.date }
        var velocities: [(Date, Double)] = []
        for i in 1..<sorted.count {
            guard let w1 = sorted[i-1].weightKg, let w2 = sorted[i].weightKg else { continue }
            let days = Calendar.current.dateComponents([.day], from: sorted[i-1].date, to: sorted[i].date).day ?? 1
            if days > 0 {
                velocities.append((sorted[i].date, (w2 - w1) / Double(days)))
            }
        }
        return zScoreInsights(
            data: velocities,
            title: "Weight Change",
            positiveMessage: "Unusually large weight increase detected.",
            negativeMessage: "Unusually large weight decrease detected.",
            positiveDirection: TrendDirection.up,
            negativeDirection: TrendDirection.down
        )
    }

    /// Detects unusually high or low overall wellbeing scores using z-score analysis.
    /// Returns empty array if fewer than 7 check-ins.
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records to analyze.
    /// - Returns: Array of OutlierInsight for detected score anomalies.
    private static func scoreOutliers(checkIns: [DailyCheckIn]) -> [OutlierInsight] {
        let data = checkIns.sorted { $0.date < $1.date }.map { ($0.date, Double($0.overallScore)) }
        return zScoreInsights(
            data: data,
            title: "Wellbeing Score",
            positiveMessage: "Your score today is unusually high — great day!",
            negativeMessage: "Your score today is unusually low — consider checking in with your doctor.",
            positiveDirection: .up,
            negativeDirection: .down
        )
    }

    /// Detects unusual daily water intake using z-score analysis.
    /// Ignores check-ins without water data; returns empty array if insufficient data points.
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records to analyze.
    /// - Returns: Array of OutlierInsight for detected water intake anomalies.
    private static func waterOutliers(checkIns: [DailyCheckIn]) -> [OutlierInsight] {
        let data = checkIns.sorted { $0.date < $1.date }.compactMap { c -> (Date, Double)? in
            guard let w = c.waterLitres else { return nil }
            return (c.date, w)
        }
        return zScoreInsights(
            data: data,
            title: "Water Intake",
            positiveMessage: "Water intake was exceptionally high today.",
            negativeMessage: "Water intake was unusually low — stay hydrated!",
            positiveDirection: .up,
            negativeDirection: .down
        )
    }

    /// Detects unusual heart rate values. Currently disabled (heart rate data resides in HealthSnapshot, not DailyCheckIn).
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records (not used).
    /// - Returns: Empty array.
    private static func heartRateOutliers(checkIns: [DailyCheckIn]) -> [OutlierInsight] {
        // Heart rate is in HealthSnapshot, not DailyCheckIn — skip for now
        return []
    }

    /// Computes z-scores for a data series and generates OutlierInsight for the last 3 values exceeding the threshold.
    /// Requires at least 7 data points and positive standard deviation; returns empty array otherwise.
    /// - Parameters:
    ///   - data: Array of (Date, Double) tuples representing timestamped measurements.
    ///   - title: Title for generated insights (e.g., "Weight Change").
    ///   - positiveMessage: Message shown when z-score > threshold.
    ///   - negativeMessage: Message shown when z-score < -threshold.
    ///   - positiveDirection: Trend direction for positive outliers.
    ///   - negativeDirection: Trend direction for negative outliers.
    /// - Returns: Array of OutlierInsight for detected anomalies in the last 3 entries.
    private static func zScoreInsights(
        data: [(Date, Double)],
        title: String,
        positiveMessage: String,
        negativeMessage: String,
        positiveDirection: TrendDirection,
        negativeDirection: TrendDirection
    ) -> [OutlierInsight] {
        guard data.count >= minimumDataPoints else { return [] }
        let values = data.map { $0.1 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        let sd = sqrt(variance)
        guard sd > 0 else { return [] }

        var insights: [OutlierInsight] = []
        for (date, value) in data.suffix(3) {
            let z = (value - mean) / sd
            if z > zThreshold {
                insights.append(OutlierInsight(title: title, message: positiveMessage, trend: positiveDirection, date: date))
            } else if z < -zThreshold {
                insights.append(OutlierInsight(title: title, message: negativeMessage, trend: negativeDirection, date: date))
            }
        }
        return insights
    }
}
