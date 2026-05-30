import HealthKit

class HeartRateReader {
    private let store: HKHealthStore

    /// Initializes the reader with a HealthKit store.
    /// - Parameters:
    ///   - store: The HKHealthStore used to query resting heart rate data.
    init(store: HKHealthStore) {
        self.store = store
    }

    /// Reads the resting heart rate for a specific date from HealthKit.
    /// - Parameters:
    ///   - date: The date to fetch resting heart rate for.
    /// - Returns: Average resting heart rate in BPM, or nil if no data is available.
    static func readRestingHeartRate(for date: Date) async -> Double? {
        let store = HealthKitManager.shared.store
        let heartRateType = HKQuantityType(.restingHeartRate)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: heartRateType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )

        guard let samples = try? await descriptor.result(for: store), !samples.isEmpty else {
            return nil
        }

        let unit = HKUnit.count().unitDivided(by: .minute())
        let total = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: unit) }
        return total / Double(samples.count)
    }

    /// Fetches average daily resting heart rate readings for the past 90 days.
    /// Calculates daily statistics for each day and returns sorted by date ascending.
    /// - Returns: Array of DailyHeartRate readings sorted by date (oldest first). Returns empty array if no data.
    /// - Throws: HKError if the HealthKit query fails or authorization is denied.
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
