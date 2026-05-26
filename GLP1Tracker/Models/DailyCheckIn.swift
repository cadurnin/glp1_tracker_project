import Foundation
import SwiftData

@Model
final class DailyCheckIn {
    var id: UUID
    var date: Date
    var weightKg: Double?
    var waterLitres: Double?
    var overallScore: Int
    var injectionLogId: UUID?
    var cycleDay: Int
    @Relationship(deleteRule: .cascade) var symptoms: [SymptomEntry]
    var healthSnapshotId: UUID?

    init(
        date: Date = Date(),
        weightKg: Double? = nil,
        waterLitres: Double? = nil,
        overallScore: Int = 5,
        injectionLogId: UUID? = nil,
        cycleDay: Int = 1,
        healthSnapshotId: UUID? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.weightKg = weightKg
        self.waterLitres = waterLitres
        self.overallScore = overallScore
        self.injectionLogId = injectionLogId
        self.cycleDay = cycleDay
        self.symptoms = []
        self.healthSnapshotId = healthSnapshotId
    }
}
