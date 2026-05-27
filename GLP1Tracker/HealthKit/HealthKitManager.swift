import HealthKit
import Foundation

final class HealthKitManager {
    static let shared = HealthKitManager()
    let store = HKHealthStore()

    private init() {}

    static let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .bodyMass, .dietaryWater, .restingHeartRate, .heartRate
        ]
        for id in quantityIds {
            types.insert(HKQuantityType(id))
        }
        types.insert(HKCategoryType(.sleepAnalysis))
        return types
    }()

    static let writeTypes: Set<HKSampleType> = {
        var types: Set<HKSampleType> = []
        let quantityIds: [HKQuantityTypeIdentifier] = [.bodyMass, .dietaryWater]
        for id in quantityIds {
            types.insert(HKQuantityType(id))
        }
        let categoryIds: [HKCategoryTypeIdentifier] = [
            .nausea, .vomiting, .diarrhea, .constipation, .abdominalCramps,
            .fatigue, .appetiteChanges, .headache, .dizziness, .heartburn,
            .bloating, .rapidPoundingOrFlutteringHeartbeat, .hotFlashes
        ]
        for id in categoryIds {
            types.insert(HKCategoryType(id))
        }
        return types
    }()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: HealthKitManager.writeTypes,
                                             read: HealthKitManager.readTypes)
    }
}
