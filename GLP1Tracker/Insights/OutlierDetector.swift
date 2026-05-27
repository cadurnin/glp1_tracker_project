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

    static func detect(checkIns: [DailyCheckIn]) -> [OutlierInsight] {
        guard checkIns.count >= minimumDataPoints else { return [] }
        var insights: [OutlierInsight] = []

        insights += weightOutliers(checkIns: checkIns)
        insights += scoreOutliers(checkIns: checkIns)
        insights += waterOutliers(checkIns: checkIns)
        insights += heartRateOutliers(checkIns: checkIns)

        return insights
    }

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

    private static func heartRateOutliers(checkIns: [DailyCheckIn]) -> [OutlierInsight] {
        // Heart rate is in HealthSnapshot, not DailyCheckIn — skip for now
        return []
    }

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
