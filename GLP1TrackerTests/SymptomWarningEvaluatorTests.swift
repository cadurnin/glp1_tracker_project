import XCTest
@testable import GLP1Tracker

final class SymptomWarningEvaluatorTests: XCTestCase {

    // MARK: - Helpers

    private func entry(id: String, present: Bool) -> SymptomEntry {
        SymptomEntry(
            symptomId: id,
            present: present,
            severity: nil,
            date: Date(),
            checkInId: UUID()
        )
    }

    /// Builds a full set of SymptomEntry values with only the listed IDs marked present.
    private func entriesWithPresent(_ ids: [String]) -> [SymptomEntry] {
        SymptomList.all.map { symptom in
            entry(id: symptom.id, present: ids.contains(symptom.id))
        }
    }

    // MARK: - No warnings

    func test_evaluate_returns_empty_when_no_symptoms_are_present() {
        let entries = entriesWithPresent([])
        XCTAssertTrue(SymptomWarningEvaluator.evaluate(entries: entries).isEmpty)
    }

    func test_evaluate_returns_empty_for_normal_level_symptom() {
        // nausea has warningLevel .normal → no warning expected
        let entries = entriesWithPresent(["nausea"])
        XCTAssertTrue(SymptomWarningEvaluator.evaluate(entries: entries).isEmpty)
    }

    // MARK: - Stop-drug individual warnings

    func test_evaluate_returns_stopDrug_warning_for_pancreatitis() {
        let entries = entriesWithPresent(["pancreatitis"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let stopDrug = results.filter { $0.level == .stopDrug }
        XCTAssertFalse(stopDrug.isEmpty)
    }

    func test_evaluate_returns_stopDrug_warning_for_gallbladder() {
        let entries = entriesWithPresent(["gallbladder"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let stopDrug = results.filter { $0.level == .stopDrug }
        XCTAssertFalse(stopDrug.isEmpty)
    }

    func test_evaluate_returns_stopDrug_warning_for_thyroid_tumor() {
        let entries = entriesWithPresent(["thyroid_tumor"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        XCTAssertTrue(results.contains { $0.symptomIds.contains("thyroid_tumor") && $0.level == .stopDrug })
    }

    func test_evaluate_returns_stopDrug_warning_for_allergic_reaction() {
        let entries = entriesWithPresent(["allergic_reaction"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        XCTAssertTrue(results.contains { $0.symptomIds.contains("allergic_reaction") && $0.level == .stopDrug })
    }

    func test_evaluate_stopDrug_warning_symptomIds_contains_the_triggering_symptom() {
        let entries = entriesWithPresent(["pancreatitis"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let pancreatitisResult = results.first { $0.symptomIds.contains("pancreatitis") }
        XCTAssertNotNil(pancreatitisResult)
    }

    func test_evaluate_stopDrug_warning_message_is_non_empty() {
        let entries = entriesWithPresent(["pancreatitis"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let result = results.first { $0.symptomIds.contains("pancreatitis") }
        XCTAssertFalse(result?.message.isEmpty ?? true)
    }

    // MARK: - Consult-doctor individual warnings

    func test_evaluate_returns_consultDoctor_warning_for_vomiting() {
        let entries = entriesWithPresent(["vomiting"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        XCTAssertTrue(results.contains { $0.symptomIds.contains("vomiting") && $0.level == .consultDoctor })
    }

    func test_evaluate_returns_consultDoctor_warning_for_palpitations() {
        let entries = entriesWithPresent(["palpitations"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        XCTAssertTrue(results.contains { $0.symptomIds.contains("palpitations") && $0.level == .consultDoctor })
    }

    func test_evaluate_returns_consultDoctor_warning_for_vision_changes() {
        let entries = entriesWithPresent(["vision_changes"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        XCTAssertTrue(results.contains { $0.symptomIds.contains("vision_changes") && $0.level == .consultDoctor })
    }

    func test_evaluate_consultDoctor_warning_message_is_non_empty() {
        let entries = entriesWithPresent(["vomiting"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let result = results.first { $0.symptomIds.contains("vomiting") }
        XCTAssertFalse(result?.message.isEmpty ?? true)
    }

    // MARK: - Kidney combination rule

    func test_evaluate_combination_rule_fires_for_dark_urine_dizziness_and_infrequent_urination() {
        let entries = entriesWithPresent(["dark_urine", "dizziness", "infrequent_urination"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let combinationResult = results.first {
            $0.symptomIds.contains("dark_urine") &&
            $0.symptomIds.contains("dizziness") &&
            $0.symptomIds.contains("infrequent_urination")
        }
        XCTAssertNotNil(combinationResult)
    }

    func test_evaluate_combination_rule_produces_stopDrug_level() {
        let entries = entriesWithPresent(["dark_urine", "dizziness", "infrequent_urination"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let combinationResult = results.first {
            $0.symptomIds.contains("dark_urine") &&
            $0.symptomIds.contains("dizziness") &&
            $0.symptomIds.contains("infrequent_urination")
        }
        XCTAssertEqual(combinationResult?.level, .stopDrug)
    }

    func test_evaluate_combination_rule_does_not_fire_without_dizziness() {
        // Missing dizziness — combination rule should not trigger
        let entries = entriesWithPresent(["dark_urine", "infrequent_urination"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let combinationResult = results.first {
            $0.symptomIds.contains("dark_urine") &&
            $0.symptomIds.contains("infrequent_urination") &&
            $0.symptomIds.count == 3
        }
        XCTAssertNil(combinationResult)
    }

    func test_evaluate_combination_rule_does_not_fire_without_dark_urine() {
        let entries = entriesWithPresent(["dizziness", "infrequent_urination"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let combinationResult = results.first {
            $0.symptomIds.contains("dark_urine") &&
            $0.symptomIds.contains("dizziness") &&
            $0.symptomIds.contains("infrequent_urination")
        }
        XCTAssertNil(combinationResult)
    }

    func test_evaluate_combination_rule_does_not_fire_without_infrequent_urination() {
        let entries = entriesWithPresent(["dark_urine", "dizziness"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let combinationResult = results.first {
            $0.symptomIds.contains("dark_urine") &&
            $0.symptomIds.contains("dizziness") &&
            $0.symptomIds.contains("infrequent_urination")
        }
        XCTAssertNil(combinationResult)
    }

    // MARK: - Multiple symptoms produce multiple results

    func test_evaluate_multiple_stopDrug_symptoms_each_produce_a_result() {
        let entries = entriesWithPresent(["pancreatitis", "gallbladder"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let stopDrugResults = results.filter { $0.level == .stopDrug }
        XCTAssertGreaterThanOrEqual(stopDrugResults.count, 2)
    }

    func test_evaluate_mixing_stop_drug_and_consult_doctor_symptoms_produces_results_for_both() {
        let entries = entriesWithPresent(["pancreatitis", "vomiting"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        XCTAssertTrue(results.contains { $0.level == .stopDrug })
        XCTAssertTrue(results.contains { $0.level == .consultDoctor })
    }

    // MARK: - WarningResult identity

    func test_evaluate_each_result_has_unique_id() {
        let entries = entriesWithPresent(["pancreatitis", "vomiting", "palpitations"])
        let results = SymptomWarningEvaluator.evaluate(entries: entries)
        let ids = results.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
