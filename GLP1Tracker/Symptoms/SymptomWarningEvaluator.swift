import Foundation

struct WarningResult: Identifiable {
    let id = UUID()
    let message: String
    let level: WarningLevel
    let symptomIds: [String]
}

enum SymptomWarningEvaluator {
    /// Evaluates symptom entries against warning rules and combination heuristics.
    /// Generates individual stop-drug warnings, a kidney stress combination rule, and consult-doctor warnings.
    /// - Parameters:
    ///   - entries: Array of SymptomEntry records to evaluate (present = true entries trigger warnings).
    /// - Returns: Array of WarningResult with messages and warning levels.
    static func evaluate(entries: [SymptomEntry]) -> [WarningResult] {
        var results: [WarningResult] = []
        let presentIds = Set(entries.filter { $0.present }.map { $0.symptomId })

        // Individual stop-drug warnings
        let stopDrugSymptoms = SymptomList.all.filter {
            $0.warningLevel == .stopDrug && presentIds.contains($0.id)
        }
        for symptom in stopDrugSymptoms {
            results.append(WarningResult(
                message: "\(symptom.name) — contact your prescriber immediately and consider stopping the medication.",
                level: .stopDrug,
                symptomIds: [symptom.id]
            ))
        }

        // Combination rule: dark_urine + dizziness + infrequent_urination → kidney injury warning
        if presentIds.contains("dark_urine") &&
           presentIds.contains("dizziness") &&
           presentIds.contains("infrequent_urination") {
            let alreadyCovered = results.contains { $0.symptomIds.contains("kidney_injury") }
            if !alreadyCovered {
                results.append(WarningResult(
                    message: "Dark urine, dizziness, and infrequent urination together may indicate kidney stress. Contact your doctor.",
                    level: .stopDrug,
                    symptomIds: ["dark_urine", "dizziness", "infrequent_urination"]
                ))
            }
        }

        // Consult-doctor warnings
        let consultSymptoms = SymptomList.all.filter { symptom in
            symptom.warningLevel == .consultDoctor &&
            presentIds.contains(symptom.id) &&
            !results.contains(where: { $0.symptomIds.contains(symptom.id) })
        }
        for symptom in consultSymptoms {
            results.append(WarningResult(
                message: "\(symptom.name) — mention this to your healthcare provider at your next visit.",
                level: .consultDoctor,
                symptomIds: [symptom.id]
            ))
        }

        return results
    }
}
