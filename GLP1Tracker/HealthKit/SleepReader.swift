import HealthKit
import Foundation

struct SleepData {
    var totalHours: Double = 0
    var remHours: Double = 0
    var deepHours: Double = 0
    var bedtime: Date?
    var wakeTime: Date?
}

struct SleepReader {
    /// Reads sleep data from HealthKit for the sleep window preceding a given date.
    /// Sleep window spans from 15:00 (3 PM) the previous day to 12:00 (noon) on the given date.
    /// Accumulates total, REM, and deep sleep hours; tracks earliest bedtime and latest wake time.
    /// - Parameters:
    ///   - date: The date to fetch sleep data for (represents the morning after sleep).
    /// - Returns: SleepData with aggregated sleep metrics, or nil if no sleep samples are found.
    static func readSleep(for date: Date) async -> SleepData? {
        let store = HealthKitManager.shared.store
        let calendar = Calendar.current
        // Sleep window: previous afternoon to morning of `date`
        let sleepStart = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -1, to: date)!)!
        let sleepEnd = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!

        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: sleepStart, end: sleepEnd)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )

        guard let samples = try? await descriptor.result(for: store), !samples.isEmpty else {
            return nil
        }

        var data = SleepData()
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        ]

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
            let val = sample.value

            if asleepValues.contains(val) {
                data.totalHours += duration
                if data.bedtime == nil || sample.startDate < data.bedtime! {
                    data.bedtime = sample.startDate
                }
                if data.wakeTime == nil || sample.endDate > data.wakeTime! {
                    data.wakeTime = sample.endDate
                }
            }
            if val == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                data.remHours += duration
            }
            if val == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                data.deepHours += duration
            }
        }

        return data.totalHours > 0 ? data : nil
    }
}
