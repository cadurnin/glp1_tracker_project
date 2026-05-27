import SwiftData
import Foundation

@Model
final class SymptomEntry {
    var symptomId: String = ""
    var present: Bool = false
    var severity: Int?
    var date: Date = Date()
    var checkInId: UUID = UUID()

    init(symptomId: String, present: Bool, severity: Int? = nil, date: Date, checkInId: UUID) {
        self.symptomId = symptomId
        self.present = present
        self.severity = severity
        self.date = date
        self.checkInId = checkInId
    }
}
