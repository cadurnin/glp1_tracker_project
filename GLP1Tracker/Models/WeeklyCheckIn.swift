import Foundation
import SwiftData

@Model
final class WeeklyCheckIn {
    var weekStartDate: Date
    var weightKg: Double?
    var doseAtTimeOfCheckIn: Double
    var weekRating: Int
    var notes: String?
    var symptomSummary: String?

    init(
        weekStartDate: Date,
        weightKg: Double? = nil,
        doseAtTimeOfCheckIn: Double,
        weekRating: Int,
        notes: String? = nil,
        symptomSummary: String? = nil
    ) {
        self.weekStartDate = weekStartDate
        self.weightKg = weightKg
        self.doseAtTimeOfCheckIn = doseAtTimeOfCheckIn
        self.weekRating = weekRating
        self.notes = notes
        self.symptomSummary = symptomSummary
    }
}
