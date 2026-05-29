import Foundation

/// Aggregated statistics for resting heart rate over a 90-day window with outlier detection.
struct HeartRateStats {
    /// Mean resting heart rate in beats per minute over the last 90 days.
    let ninetyDayMean: Double
    /// Standard deviation of resting heart rate over 90 days.
    let standardDeviation: Double
    /// Upper threshold for outlier detection (mean + 2 * standard deviation).
    let upperThreshold: Double
    /// Lower threshold for outlier detection (mean - 2 * standard deviation).
    let lowerThreshold: Double
    /// Average resting heart rate in beats per minute for the last 7 days.
    let sevenDayAverage: Double
    /// Days with readings outside the upper/lower thresholds.
    let outliers: [DailyHeartRate]
    /// True if at least 7 readings exist in the 90-day window; false otherwise (stats unreliable).
    let hasEnoughData: Bool
}
