import HealthKit
import Foundation

struct HealthKitWriter {
    /// Writes check-in data to HealthKit, converting weight, water, and symptoms to HKSample values.
    /// Silently fails if HealthKit is not available on the device; logs errors to console.
    /// - Parameters:
    ///   - checkIn: The DailyCheckIn to write to HealthKit.
    static func write(checkIn: DailyCheckIn) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let store = HealthKitManager.shared.store
        let samples = buildSamples(from: checkIn)
        guard !samples.isEmpty else { return }
        do {
            try await store.save(samples)
        } catch {
            print("[HealthKitWriter] Save failed: \(error)")
        }
    }

    /// Constructs HKSample values from a check-in. Pure — no async, no store reference.
    private static func buildSamples(from checkIn: DailyCheckIn) -> [HKSample] {
        var samples: [HKSample] = []
        let date = checkIn.date

        if let weightKg = checkIn.weightKg {
            let type = HKQuantityType(.bodyMass)
            let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
            samples.append(HKQuantitySample(type: type, quantity: quantity, start: date, end: date))
        }

        if let water = checkIn.waterLitres {
            let type = HKQuantityType(.dietaryWater)
            let quantity = HKQuantity(unit: .liter(), doubleValue: water)
            samples.append(HKQuantitySample(type: type, quantity: quantity, start: date, end: date))
        }

        for entry in checkIn.symptoms where entry.present {
            guard let symptom = SymptomList.all.first(where: { $0.id == entry.symptomId }),
                  let hkId = symptom.healthKitTypeId else { continue }

            let categoryId = HKCategoryTypeIdentifier(rawValue: hkId)
            let categoryType = HKCategoryType(categoryId)

            if entry.symptomId == "appetite_decreased" {
                samples.append(HKCategorySample(
                    type: categoryType,
                    value: HKCategoryValueAppetiteChanges.decreased.rawValue,
                    start: date, end: date
                ))
            } else {
                samples.append(HKCategorySample(
                    type: categoryType,
                    value: HKCategoryValuePresence.present.rawValue,
                    start: date, end: date
                ))
            }
        }

        return samples
    }
}
