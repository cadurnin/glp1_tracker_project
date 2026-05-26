import Foundation
import SwiftData

@Model
final class HealthSnapshot {
    var id: UUID
    var date: Date
    // Auto-pulled from Watch via HealthKit
    var restingHeartRate: Double?
    var sleepHours: Double?
    var sleepREM: Double?
    var sleepDeep: Double?
    var sleepBedtime: Date?
    var sleepWakeTime: Date?
    // Written to HealthKit then mirrored back
    var weightKg: Double?
    var waterLitres: Double?
    // Symptoms with HealthKit equivalents
    var nausea: Bool
    var vomiting: Bool
    var diarrhea: Bool
    var constipation: Bool
    var heartburn: Bool
    var abdominalCramps: Bool
    var bloating: Bool
    var fatigue: Bool
    var headache: Bool
    var dizziness: Bool
    var shortnessOfBreath: Bool
    var moodChanges: Bool
    var hairLoss: Bool
    var appetiteChanges: Bool
    // SwiftData-only symptoms
    var darkUrine: Bool
    var infrequentUrination: Bool
    var brainFog: Bool
    var neckLump: Bool
    var hoarseness: Bool
    var troubleSwallowing: Bool
    var injectionSiteReaction: Bool
    var abdominalPainRadiating: Bool
    var absoluteConstipation: Bool
    var visionChanges: Bool
    var hypoglycemiaSymptoms: Bool
    var rapidHeartRate: Bool
    var upperStomachPain: Bool
    var extremeBloating: Bool

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.nausea = false
        self.vomiting = false
        self.diarrhea = false
        self.constipation = false
        self.heartburn = false
        self.abdominalCramps = false
        self.bloating = false
        self.fatigue = false
        self.headache = false
        self.dizziness = false
        self.shortnessOfBreath = false
        self.moodChanges = false
        self.hairLoss = false
        self.appetiteChanges = false
        self.darkUrine = false
        self.infrequentUrination = false
        self.brainFog = false
        self.neckLump = false
        self.hoarseness = false
        self.troubleSwallowing = false
        self.injectionSiteReaction = false
        self.abdominalPainRadiating = false
        self.absoluteConstipation = false
        self.visionChanges = false
        self.hypoglycemiaSymptoms = false
        self.rapidHeartRate = false
        self.upperStomachPain = false
        self.extremeBloating = false
    }
}
