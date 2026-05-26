import Foundation

struct WarningResult: Identifiable {
    let id = UUID()
    let symptom: Symptom
    let message: String
    let level: WarningLevel
}

struct SymptomWarningEvaluator {
    static func evaluate(entries: [SymptomEntry]) -> [WarningResult] {
        var results: [WarningResult] = []
        let presentIds = Set(entries.filter { $0.present }.map { $0.symptomId })

        // Combination rule: dark_urine + dizziness + infrequent_urination → kidney injury warning
        if presentIds.contains("dark_urine") && presentIds.contains("dizziness") && presentIds.contains("infrequent_urination") {
            let combo = Symptom(
                id: "kidney_injury_combo",
                name: "Dehydration Warning Combination",
                category: .rare,
                tracksSeverity: false,
                warningLevel: .stopDrug,
                warningMessage: "These symptoms together may indicate acute kidney injury from dehydration. Stop taking your medication and seek medical care immediately."
            )
            results.append(WarningResult(symptom: combo, message: combo.warningMessage!, level: .stopDrug))
        }

        let comboIds: Set<String> = ["dark_urine", "dizziness", "infrequent_urination"]
        let comboActive = comboIds.isSubset(of: presentIds)

        for entry in entries where entry.present {
            guard let symptom = SymptomList.symptom(for: entry.symptomId),
                  symptom.warningLevel != .none,
                  let message = symptom.warningMessage
            else { continue }

            // Individual caution warnings for combo symptoms are suppressed when combo fires
            if comboActive && comboIds.contains(entry.symptomId) && symptom.warningLevel == .caution {
                continue
            }

            results.append(WarningResult(symptom: symptom, message: message, level: symptom.warningLevel))
        }

        // stopDrug warnings first, then caution
        results.sort {
            if $0.level == $1.level { return false }
            return $0.level == .stopDrug
        }

        return results
    }
}
