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

    /// Initializes an injection log entry with dose and optional site notes.
    /// - Parameters:
    ///   - date: The date of the injection. Defaults to today.
    ///   - time: The time the injection was given. Defaults to current time.
    ///   - doseMg: Dose in milligrams. Defaults to 0.5.
    ///   - doseLabel: Human-readable dose label (e.g., "0.5 mg"). Defaults to "0.5 mg".
    ///   - injectionSiteNote: Optional note about the injection site or reaction.
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

    /// Calculates the cycle day (1-based) since the most recent injection.
    /// - Parameters:
    ///   - lastInjectionDate: The date of the last injection, or nil if no prior injections.
    /// - Returns: Cycle day as an integer (minimum 1). Returns 1 if no prior injection exists.
    static func cycleDay(from lastInjectionDate: Date?) -> Int {
        guard let last = lastInjectionDate else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return max(1, days + 1)
    }
}
