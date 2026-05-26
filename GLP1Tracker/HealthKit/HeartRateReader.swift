import HealthKit
import Foundation

struct HeartRateReader {
    private let store: HKHealthStore

    init(store: HKHealthStore = HealthKitManager.shared.store) {
        self.store = store
    }

    func readTodayRestingHeartRate() async -> Double? {
        let type = HKQuantityType(.restingHeartRate)
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        do {
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: type, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
                limit: 1
            )
            let results = try await descriptor.result(for: store)
            if let sample = results.first {
                return sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        } catch {}
        return await readAverageHeartRateToday()
    }

    private func readAverageHeartRateToday() async -> Double? {
        let type = HKQuantityType(.heartRate)
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        do {
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: .quantitySample(type: type, predicate: predicate),
                options: .discreteAverage
            )
            let stats = try await descriptor.result(for: store)
            return stats?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
        } catch {
            return nil
        }
    }
}
