import HealthKit

class HeartRateReader {
    private let store: HKHealthStore

    init(store: HKHealthStore) {
        self.store = store
    }

    func fetchLast90Days() async throws -> [DailyHeartRate] {
        let heartRateType = HKQuantityType(.restingHeartRate)
        let calendar = Calendar.current
        let now = Date()
        let anchorDate = calendar.startOfDay(for: now)
        let startDate = calendar.date(byAdding: .day, value: -90, to: anchorDate)!
        let interval = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
        let unit = HKUnit.count().unitDivided(by: .minute())

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results else {
                    continuation.resume(returning: [])
                    return
                }

                var readings: [DailyHeartRate] = []
                results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                    guard let quantity = statistics.averageQuantity() else { return }
                    let bpm = quantity.doubleValue(for: unit)
                    readings.append(DailyHeartRate(date: statistics.startDate, bpm: bpm))
                }

                continuation.resume(returning: readings.sorted { $0.date < $1.date })
            }

            store.execute(query)
        }
    }
}
