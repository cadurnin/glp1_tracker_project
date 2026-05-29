import Foundation

struct HeartRateAnalyzer {
    private static let stdDevMultiplier = 2.0

    /// Analyzes resting heart rate readings to compute statistics and identify outliers.
    /// Requires at least 7 readings; returns empty stats with hasEnoughData=false if below threshold.
    /// - Parameters:
    ///   - readings: Array of DailyHeartRate measurements (can be empty).
    /// - Returns: HeartRateStats with 90-day mean, standard deviation, outliers, and 7-day average.
    static func analyze(_ readings: [DailyHeartRate]) -> HeartRateStats {
        guard readings.count >= 7 else {
            return HeartRateStats(
                ninetyDayMean: 0,
                standardDeviation: 0,
                upperThreshold: 0,
                lowerThreshold: 0,
                sevenDayAverage: 0,
                outliers: [],
                hasEnoughData: false
            )
        }

        let count = Double(readings.count)
        let mean = readings.reduce(0.0) { $0 + $1.bpm } / count
        let variance = readings.reduce(0.0) { $0 + pow($1.bpm - mean, 2) } / count
        let stdDev = sqrt(variance)
        let upper = mean + stdDevMultiplier * stdDev
        let lower = mean - stdDevMultiplier * stdDev
        let outliers = readings.filter { $0.bpm > upper || $0.bpm < lower }

        let last7 = readings.suffix(7)
        let sevenDayAvg = last7.reduce(0.0) { $0 + $1.bpm } / Double(last7.count)

        return HeartRateStats(
            ninetyDayMean: mean,
            standardDeviation: stdDev,
            upperThreshold: upper,
            lowerThreshold: lower,
            sevenDayAverage: sevenDayAvg,
            outliers: outliers,
            hasEnoughData: true
        )
    }
}
