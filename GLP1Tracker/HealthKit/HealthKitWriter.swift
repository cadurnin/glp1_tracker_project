import HealthKit
import Foundation

struct HealthKitWriter {
    private let store: HKHealthStore

    init(store: HKHealthStore = HealthKitManager.shared.store) {
        self.store = store
    }

    func writeWeight(_ kg: Double, date: Date) async throws {
        let type = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await store.save(sample)
    }

    func writeWater(_ litres: Double, date: Date) async throws {
        let type = HKQuantityType(.dietaryWater)
        let quantity = HKQuantity(unit: .liter(), doubleValue: litres)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await store.save(sample)
    }

    func writeSymptoms(_ entries: [SymptomEntry], date: Date) async {
        let presenceMap: [(String, HKCategoryTypeIdentifier)] = [
            ("nausea", .nausea),
            ("vomiting", .vomiting),
            ("diarrhea", .diarrhea),
            ("constipation", .constipation),
            ("indigestion", .heartburn),
            ("abdominal_pain_general", .abdominalCramps),
            ("bloating", .bloating),
            ("fatigue", .fatigue),
            ("headache", .headache),
            ("dizziness", .dizziness),
            ("shortness_of_breath", .shortnessOfBreath),
            ("mood_changes", .moodChanges),
            ("hair_loss", .hairLoss),
        ]

        for (symptomId, categoryId) in presenceMap {
            guard let entry = entries.first(where: { $0.symptomId == symptomId }) else { continue }
            let value = entry.present
                ? HKCategoryValuePresence.present.rawValue
                : HKCategoryValuePresence.notPresent.rawValue
            let sample = HKCategorySample(
                type: HKCategoryType(categoryId),
                value: value,
                start: date,
                end: date
            )
            try? await store.save(sample)
        }

        // Appetite uses its own enum value type
        if let entry = entries.first(where: { $0.symptomId == "appetite_loss" }) {
            let value = entry.present
                ? HKCategoryValueAppetiteChanges.decreased.rawValue
                : HKCategoryValueAppetiteChanges.noChange.rawValue
            let sample = HKCategorySample(
                type: HKCategoryType(.appetiteChanges),
                value: value,
                start: date,
                end: date
            )
            try? await store.save(sample)
        }
    }
}
