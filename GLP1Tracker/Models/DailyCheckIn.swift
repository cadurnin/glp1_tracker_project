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
