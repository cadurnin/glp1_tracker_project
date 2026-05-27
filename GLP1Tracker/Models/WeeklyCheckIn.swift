import SwiftData
import Foundation

@Model
final class WeeklyCheckIn {
    var id: UUID = UUID()
    var weekStartDate: Date = Date()
    var weightKg: Double?
    var doseAtTimeOfCheckIn: Double = 0.5
    var weekRating: Int = 5
    var notes: String?
    var symptomSummary: String?

    init(weekStartDate: Date = Date(),
         weightKg: Double? = nil,
         doseAtTimeOfCheckIn: Double = 0.5,
         weekRating: Int = 5,
         notes: String? = nil,
         symptomSummary: String? = nil) {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.weightKg = weightKg
        self.doseAtTimeOfCheckIn = doseAtTimeOfCheckIn
        self.weekRating = weekRating
        self.notes = notes
        self.symptomSummary = symptomSummary
    }
}
