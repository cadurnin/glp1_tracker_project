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

    /// Initializes a weekly check-in review for a given week.
    /// - Parameters:
    ///   - weekStartDate: The Monday (or start) date of the week being reviewed. Defaults to this week.
    ///   - weightKg: Body weight in kilograms, optional.
    ///   - doseAtTimeOfCheckIn: Current dose in milligrams at the time of this review. Defaults to 0.5.
    ///   - weekRating: User's overall rating of the week from 1–10. Defaults to 5.
    ///   - notes: Optional freeform notes about the week.
    ///   - symptomSummary: Optional summary of the week's dominant symptoms or trends.
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
