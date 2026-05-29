import Foundation

struct HeartRateStats {
    let ninetyDayMean: Double
    let standardDeviation: Double
    let upperThreshold: Double      // mean + (2 * stdDev)
    let lowerThreshold: Double      // mean - (2 * stdDev)
    let sevenDayAverage: Double
    let outliers: [DailyHeartRate]  // days outside upper/lower threshold
    let hasEnoughData: Bool         // false if fewer than 7 readings exist
}
