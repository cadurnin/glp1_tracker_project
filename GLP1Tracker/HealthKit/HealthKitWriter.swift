import HealthKit
import Foundation

struct HealthKitWriter {
    static func write(checkIn: DailyCheckIn) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let store = HealthKitManager.shared.store
        var samples: [HKSample] = []
        let date = checkIn.date

        // Weight
        if let weightKg = checkIn.weightKg {
            let type = HKQuantityType(.bodyMass)
            let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
            samples.append(HKQuantitySample(type: type, quantity: quantity, start: date, end: date))
        }

        // Water
        if let water = checkIn.waterLitres {
            let type = HKQuantityType(.dietaryWater)
            let quantity = HKQuantity(unit: .liter(), doubleValue: water)
            samples.append(HKQuantitySample(type: type, quantity: quantity, start: date, end: date))
        }

        // Symptoms
        for entry in checkIn.symptoms where entry.present {
            guard let symptom = SymptomList.all.first(where: { $0.id == entry.symptomId }),
                  let hkId = symptom.healthKitTypeId else { continue }

            let categoryId = HKCategoryTypeIdentifier(rawValue: hkId)
            let categoryType = HKCategoryType(categoryId)

            if entry.symptomId == "appetite_decreased" {
                let sample = HKCategorySample(
                    type: categoryType,
                    value: HKCategoryValueAppetiteChanges.decreased.rawValue,
                    start: date, end: date
                )
                samples.append(sample)
            } else {
                let sample = HKCategorySample(
                    type: categoryType,
                    value: HKCategoryValuePresence.present.rawValue,
                    start: date, end: date
                )
                samples.append(sample)
            }
        }

        try? await store.save(samples)
    }
}
