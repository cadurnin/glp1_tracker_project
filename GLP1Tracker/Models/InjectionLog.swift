import SwiftData
import Foundation

@Model
final class InjectionLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var time: Date = Date()
    var doseMg: Double = 0.5
    var doseLabel: String = "0.5 mg"
    var injectionSiteNote: String?

    init(date: Date = Date(),
         time: Date = Date(),
         doseMg: Double = 0.5,
         doseLabel: String = "0.5 mg",
         injectionSiteNote: String? = nil) {
        self.id = UUID()
        self.date = date
        self.time = time
        self.doseMg = doseMg
        self.doseLabel = doseLabel
        self.injectionSiteNote = injectionSiteNote
    }

    /// Returns the cycle day (1-based) since the last injection date
    static func cycleDay(from lastInjectionDate: Date?) -> Int {
        guard let last = lastInjectionDate else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return max(1, days + 1)
    }
}
