import Foundation
import SwiftData

@Model
final class SymptomEntry {
    var symptomId: String
    var present: Bool
    var severity: Int?
    var date: Date
    var checkInId: UUID

    init(
        symptomId: String,
        present: Bool,
        severity: Int? = nil,
        date: Date = Date(),
        checkInId: UUID
    ) {
        self.symptomId = symptomId
        self.present = present
        self.severity = severity
        self.date = date
        self.checkInId = checkInId
    }
}
