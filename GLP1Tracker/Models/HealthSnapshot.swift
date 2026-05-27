import SwiftData
import Foundation

@Model
final class HealthSnapshot {
    var id: UUID = UUID()
    var date: Date = Date()

    // Vitals
    var restingHeartRate: Double?
    var sleepHours: Double?
    var sleepREM: Double?
    var sleepDeep: Double?
    var sleepBedtime: Date?
    var sleepWakeTime: Date?
    var weightKg: Double?
    var waterLitres: Double?

    // Symptom mirrors
    var nausea: Bool = false
    var vomiting: Bool = false
    var diarrhea: Bool = false
    var constipation: Bool = false
    var abdominalPain: Bool = false
    var fatigue: Bool = false
    var appetiteDecreased: Bool = false
    var headache: Bool = false
    var dizziness: Bool = false
    var heartburn: Bool = false
    var indigestion: Bool = false
    var burping: Bool = false
    var bloating: Bool = false
    var drymouth: Bool = false
    var hairLoss: Bool = false
    var muscleLoss: Bool = false
    var moodChanges: Bool = false
    var lowBloodSugar: Bool = false
    var pancreatitis: Bool = false
    var gallbladder: Bool = false
    var kidneyInjury: Bool = false
    var thyroidTumor: Bool = false
    var allergicReaction: Bool = false
    var visionChanges: Bool = false
    var injectionSiteReaction: Bool = false
    var darkUrine: Bool = false
    var infrequentUrination: Bool = false
    var insomnia: Bool = false
    var hotFlashes: Bool = false
    var palpitations: Bool = false
    var sweating: Bool = false

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
    }
}
