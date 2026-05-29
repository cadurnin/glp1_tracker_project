import XCTest
@testable import GLP1Tracker

// MARK: - NOTE
// The three helpers (weightKg, waterLitres, buildSymptomEntries) were originally
// `private static` on CheckInWizardView, which made them unreachable from tests.
// They have been extracted to CheckInTransformer (GLP1Tracker/CheckIn/CheckInTransformer.swift)
// as `internal static` functions and CheckInWizardView now delegates to that type.

final class CheckInTransformerTests: XCTestCase {

    // MARK: - weightKg(from:useKg:)

    func test_weightKg_empty_string_returns_nil() {
        XCTAssertNil(CheckInTransformer.weightKg(from: "", useKg: true))
    }

    func test_weightKg_non_numeric_string_returns_nil() {
        XCTAssertNil(CheckInTransformer.weightKg(from: "abc", useKg: true))
    }

    func test_weightKg_zero_string_returns_nil() {
        XCTAssertNil(CheckInTransformer.weightKg(from: "0", useKg: true))
    }

    func test_weightKg_negative_string_returns_nil() {
        XCTAssertNil(CheckInTransformer.weightKg(from: "-5", useKg: true))
    }

    func test_weightKg_already_in_kg_returns_value_unchanged() {
        let result = CheckInTransformer.weightKg(from: "70", useKg: true)
        XCTAssertEqual(result, 70.0, accuracy: 0.000001)
    }

    func test_weightKg_decimal_kg_value_preserved() {
        let result = CheckInTransformer.weightKg(from: "72.5", useKg: true)
        XCTAssertEqual(result, 72.5, accuracy: 0.000001)
    }

    func test_weightKg_converts_lbs_to_kg() {
        // 154 lbs → ~69.853 kg
        let result = CheckInTransformer.weightKg(from: "154", useKg: false)
        XCTAssertEqual(result ?? 0, 69.853168, accuracy: 0.0001)
    }

    func test_weightKg_one_lb_converts_correctly() {
        let result = CheckInTransformer.weightKg(from: "1", useKg: false)
        XCTAssertEqual(result ?? 0, 0.453592, accuracy: 0.000001)
    }

    // MARK: - waterLitres(from:useLitres:)

    func test_waterLitres_empty_string_returns_nil() {
        XCTAssertNil(CheckInTransformer.waterLitres(from: "", useLitres: true))
    }

    func test_waterLitres_non_numeric_string_returns_nil() {
        XCTAssertNil(CheckInTransformer.waterLitres(from: "xyz", useLitres: true))
    }

    func test_waterLitres_zero_string_returns_nil() {
        XCTAssertNil(CheckInTransformer.waterLitres(from: "0", useLitres: true))
    }

    func test_waterLitres_negative_string_returns_nil() {
        XCTAssertNil(CheckInTransformer.waterLitres(from: "-1", useLitres: false))
    }

    func test_waterLitres_already_in_litres_returns_value_unchanged() {
        let result = CheckInTransformer.waterLitres(from: "2.5", useLitres: true)
        XCTAssertEqual(result, 2.5, accuracy: 0.000001)
    }

    func test_waterLitres_converts_oz_to_litres() {
        // 84.5 fl oz ≈ 2.499 L
        let result = CheckInTransformer.waterLitres(from: "84.5", useLitres: false)
        XCTAssertEqual(result ?? 0, 2.499, accuracy: 0.001)
    }

    func test_waterLitres_one_oz_converts_correctly() {
        let result = CheckInTransformer.waterLitres(from: "1", useLitres: false)
        XCTAssertEqual(result ?? 0, 0.0295735296, accuracy: 0.0000001)
    }

    // MARK: - buildSymptomEntries(answers:severities:date:checkInId:)

    func test_buildSymptomEntries_count_matches_symptom_list() {
        let entries = CheckInTransformer.buildSymptomEntries(
            answers: [:],
            severities: [:],
            date: Date(),
            checkInId: UUID()
        )
        XCTAssertEqual(entries.count, SymptomList.all.count)
    }

    func test_buildSymptomEntries_empty_answers_all_entries_not_present() {
        let entries = CheckInTransformer.buildSymptomEntries(
            answers: [:],
            severities: [:],
            date: Date(),
            checkInId: UUID()
        )
        XCTAssertTrue(entries.allSatisfy { !$0.present })
    }

    func test_buildSymptomEntries_present_symptom_is_marked_present() {
        let entries = CheckInTransformer.buildSymptomEntries(
            answers: ["nausea": true],
            severities: [:],
            date: Date(),
            checkInId: UUID()
        )
        let nausea = entries.first { $0.symptomId == "nausea" }
        XCTAssertTrue(nausea?.present == true)
    }

    func test_buildSymptomEntries_severity_attached_when_present_and_tracks_severity() {
        let entries = CheckInTransformer.buildSymptomEntries(
            answers: ["nausea": true],
            severities: ["nausea": 3],
            date: Date(),
            checkInId: UUID()
        )
        let nausea = entries.first { $0.symptomId == "nausea" }
        XCTAssertEqual(nausea?.severity, 3)
    }

    func test_buildSymptomEntries_no_severity_when_symptom_not_present() {
        let entries = CheckInTransformer.buildSymptomEntries(
            answers: ["nausea": false],
            severities: ["nausea": 3],
            date: Date(),
            checkInId: UUID()
        )
        let nausea = entries.first { $0.symptomId == "nausea" }
        XCTAssertNil(nausea?.severity)
    }

    func test_buildSymptomEntries_no_severity_for_symptom_that_does_not_track_severity() {
        // appetite_decreased has tracksSeverity = false
        let entries = CheckInTransformer.buildSymptomEntries(
            answers: ["appetite_decreased": true],
            severities: ["appetite_decreased": 5],
            date: Date(),
            checkInId: UUID()
        )
        let entry = entries.first { $0.symptomId == "appetite_decreased" }
        XCTAssertNil(entry?.severity)
    }

    func test_buildSymptomEntries_default_severity_is_one_when_none_provided() {
        let entries = CheckInTransformer.buildSymptomEntries(
            answers: ["nausea": true],
            severities: [:],
            date: Date(),
            checkInId: UUID()
        )
        let nausea = entries.first { $0.symptomId == "nausea" }
        XCTAssertEqual(nausea?.severity, 1)
    }

    func test_buildSymptomEntries_date_and_checkInId_propagated_to_all_entries() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let id = UUID()
        let entries = CheckInTransformer.buildSymptomEntries(
            answers: [:],
            severities: [:],
            date: date,
            checkInId: id
        )
        XCTAssertTrue(entries.allSatisfy { $0.date == date && $0.checkInId == id })
    }
}
