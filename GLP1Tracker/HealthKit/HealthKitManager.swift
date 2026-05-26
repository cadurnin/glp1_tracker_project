import HealthKit
import Foundation

final class HealthKitManager {
    static let shared = HealthKitManager()
    let store = HKHealthStore()

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    static let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .restingHeartRate, .bodyMass, .dietaryWater,
            .bloodPressureSystolic, .bloodPressureDiastolic, .bloodGlucose
        ]
        quantityIds.forEach { types.insert(HKQuantityType($0)) }
        let categoryIds: [HKCategoryTypeIdentifier] = [
            .sleepAnalysis, .nausea, .appetiteChanges, .vomiting
        ]
        categoryIds.forEach { types.insert(HKCategoryType($0)) }
        return types
    }()

    static let writeTypes: Set<HKSampleType> = {
        var types: Set<HKSampleType> = []
        let quantityIds: [HKQuantityTypeIdentifier] = [.bodyMass, .dietaryWater]
        quantityIds.forEach { types.insert(HKQuantityType($0)) }
        let categoryIds: [HKCategoryTypeIdentifier] = [
            .nausea, .appetiteChanges, .vomiting, .heartburn, .diarrhea,
            .constipation, .abdominalCramps, .bloating, .fatigue, .headache,
            .dizziness, .shortnessOfBreath, .moodChanges, .hairLoss
        ]
        categoryIds.forEach { types.insert(HKCategoryType($0)) }
        return types
    }()

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: Self.writeTypes, read: Self.readTypes)
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        store.authorizationStatus(for: type)
    }
}
