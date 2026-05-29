import Foundation

/// Pure transformation helpers used during check-in save.
/// All functions are free of side effects and depend only on their arguments.
enum CheckInTransformer {

    /// Converts a user-entered weight string to kilograms.
    ///
    /// - Parameters:
    ///   - input: Raw string from the weight text field.
    ///   - useKg: When `true` the value is already in kg; when `false` it is in lbs.
    /// - Returns: Weight in kg, or `nil` when the string is empty or non-positive.
    static func weightKg(from input: String, useKg: Bool) -> Double? {
        guard let val = Double(input), val > 0 else { return nil }
        return useKg ? val : UnitConverter.kgFrom(lbs: val)
    }

    /// Converts a user-entered water intake string to litres.
    ///
    /// - Parameters:
    ///   - input: Raw string from the water text field.
    ///   - useLitres: When `true` the value is already in litres; when `false` it is in fl oz.
    /// - Returns: Water in litres, or `nil` when the string is empty or non-positive.
    static func waterLitres(from input: String, useLitres: Bool) -> Double? {
        guard let val = Double(input), val > 0 else { return nil }
        return useLitres ? val : UnitConverter.litresFrom(oz: val)
    }

    /// Builds a `SymptomEntry` for every symptom in `SymptomList.all`.
    ///
    /// - Parameters:
    ///   - answers: Map of symptom id → whether the user said it was present.
    ///   - severities: Map of symptom id → severity rating (1–5).
    ///   - date: The date of the check-in.
    ///   - checkInId: The UUID of the parent `DailyCheckIn`.
    /// - Returns: One `SymptomEntry` per symptom, absent symptoms receive `present = false`.
    static func buildSymptomEntries(
        answers: [String: Bool],
        severities: [String: Int],
        date: Date,
        checkInId: UUID
    ) -> [SymptomEntry] {
        SymptomList.all.map { symptom in
            let present = answers[symptom.id] ?? false
            return SymptomEntry(
                symptomId: symptom.id,
                present: present,
                severity: present && symptom.tracksSeverity ? (severities[symptom.id] ?? 1) : nil,
                date: date,
                checkInId: checkInId
            )
        }
    }
}
