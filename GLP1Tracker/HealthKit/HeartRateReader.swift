import HealthKit
import Foundation

struct HeartRateReader {
    static func readRestingHeartRate(for date: Date) async -> Double? {
        let store = HealthKitManager.shared.store
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        // Try resting HR first
        let restingType = HKQuantityType(.restingHeartRate)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: restingType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        if let results = try? await descriptor.result(for: store),
           let sample = results.first {
            return sample.quantity.doubleValue(for: .init(from: "count/min"))
        }

        // Fallback: average of heart rate samples
        let hrType = HKQuantityType(.heartRate)
        let hrDescriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrType, predicate: predicate)],
            sortDescriptors: [],
            limit: HKObjectQueryNoLimit
        )
        if let hrResults = try? await hrDescriptor.result(for: store), !hrResults.isEmpty {
            let unit = HKUnit(from: "count/min")
            let total = hrResults.reduce(0.0) { $0 + $1.quantity.doubleValue(for: unit) }
            return total / Double(hrResults.count)
        }

        return nil
    }
}
