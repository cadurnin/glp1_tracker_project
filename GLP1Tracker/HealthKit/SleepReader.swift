import HealthKit
import Foundation

struct SleepData {
    var totalHours: Double
    var remHours: Double
    var deepHours: Double
    var bedtime: Date?
    var wakeTime: Date?
}

struct SleepReader {
    private let store: HKHealthStore

    init(store: HKHealthStore = HealthKitManager.shared.store) {
        self.store = store
    }

    func readLastNightSleep() async -> SleepData? {
        let type = HKCategoryType(.sleepAnalysis)
        let end = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: end)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        do {
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.categorySample(type: type, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
            )
            let samples = try await descriptor.result(for: store)

            let asleepValues: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
            ]
            let asleepSamples = samples.filter { asleepValues.contains($0.value) }
            guard !asleepSamples.isEmpty else { return nil }

            let duration: (Int) -> Double = { value in
                samples.filter { $0.value == value }
                    .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            }
            let totalSeconds = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

            return SleepData(
                totalHours: totalSeconds / 3600,
                remHours: duration(HKCategoryValueSleepAnalysis.asleepREM.rawValue) / 3600,
                deepHours: duration(HKCategoryValueSleepAnalysis.asleepDeep.rawValue) / 3600,
                bedtime: asleepSamples.first?.startDate,
                wakeTime: asleepSamples.last?.endDate
            )
        } catch {
            return nil
        }
    }
}
