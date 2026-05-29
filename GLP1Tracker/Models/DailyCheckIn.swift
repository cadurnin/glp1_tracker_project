import SwiftData
import Foundation

@Model
final class DailyCheckIn {
    var id: UUID = UUID()
    var date: Date = Date()
    var weightKg: Double?
    var waterLitres: Double?
    var overallScore: Int = 5
    var injectionLogId: UUID?
    var cycleDay: Int = 0
    var healthSnapshotId: UUID?

    @Relationship(deleteRule: .cascade)
    var symptoms: [SymptomEntry] = []

    /// Initializes a daily check-in record with user-reported metrics and optional injection tracking.
    /// - Parameters:
    ///   - date: The date of the check-in. Defaults to today.
    ///   - weightKg: Body weight in kilograms, optional (can be nil to represent unmeasured).
    ///   - waterLitres: Water intake in litres, optional.
    ///   - overallScore: Self-reported wellbeing score from 1–10. Defaults to 5.
    ///   - injectionLogId: UUID of associated InjectionLog if this is an injection day, nil otherwise.
    ///   - cycleDay: Days since the last injection (1-based). Defaults to 0.
    init(date: Date = Date(),
         weightKg: Double? = nil,
         waterLitres: Double? = nil,
         overallScore: Int = 5,
         injectionLogId: UUID? = nil,
         cycleDay: Int = 0) {
        self.id = UUID()
        self.date = date
        self.weightKg = weightKg
        self.waterLitres = waterLitres
        self.overallScore = overallScore
        self.injectionLogId = injectionLogId
        self.cycleDay = cycleDay
    }
}
