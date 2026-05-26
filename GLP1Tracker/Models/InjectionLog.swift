import Foundation
import SwiftData

@Model
final class InjectionLog {
    var id: UUID
    var date: Date
    var time: Date
    var doseMg: Double
    var doseLabel: String
    var injectionSiteNote: String?

    init(
        date: Date,
        time: Date,
        doseMg: Double,
        doseLabel: String,
        injectionSiteNote: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.time = time
        self.doseMg = doseMg
        self.doseLabel = doseLabel
        self.injectionSiteNote = injectionSiteNote
    }

    static func cycleDay(from lastInjectionDate: Date?) -> Int {
        guard let last = lastInjectionDate else { return 1 }
        let cal = Calendar.current
        let days = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: last),
            to: cal.startOfDay(for: Date())
        ).day ?? 0
        return max(1, days + 1)
    }
}
