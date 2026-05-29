import SwiftData
import Foundation

@Model
final class SymptomEntry {
    var symptomId: String = ""
    var present: Bool = false
    var severity: Int?
    var date: Date = Date()
    var checkInId: UUID = UUID()

    /// Initializes a symptom entry recording whether a symptom was present and, optionally, its severity.
    /// - Parameters:
    ///   - symptomId: Unique identifier for the symptom (e.g., "nausea", "vomiting").
    ///   - present: True if the symptom was reported, false otherwise.
    ///   - severity: Severity level from 1–5 if the symptom is present and trackable. Ignored if present is false.
    ///   - date: The date of the check-in when this symptom was recorded.
    ///   - checkInId: UUID of the parent DailyCheckIn.
    init(symptomId: String, present: Bool, severity: Int? = nil, date: Date, checkInId: UUID) {
        self.symptomId = symptomId
        self.present = present
        self.severity = severity
        self.date = date
        self.checkInId = checkInId
    }
}
