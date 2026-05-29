import XCTest
@testable import GLP1Tracker

final class UnitConverterTests: XCTestCase {

    // MARK: - kgFrom(lbs:)

    func test_kgFrom_known_value_one_pound() {
        XCTAssertEqual(UnitConverter.kgFrom(lbs: 1), 0.453592, accuracy: 0.000001)
    }

    func test_kgFrom_known_value_154_pounds() {
        // 154 lbs is roughly 69.853 kg — a common user weight
        XCTAssertEqual(UnitConverter.kgFrom(lbs: 154), 69.853168, accuracy: 0.00001)
    }

    func test_kgFrom_zero_returns_zero() {
        XCTAssertEqual(UnitConverter.kgFrom(lbs: 0), 0, accuracy: 0.000001)
    }

    func test_kgFrom_large_value() {
        XCTAssertEqual(UnitConverter.kgFrom(lbs: 1000), 453.592, accuracy: 0.001)
    }

    // MARK: - lbsFrom(kg:)

    func test_lbsFrom_known_value_one_kg() {
        XCTAssertEqual(UnitConverter.lbsFrom(kg: 1), 2.204623, accuracy: 0.000001)
    }

    func test_lbsFrom_zero_returns_zero() {
        XCTAssertEqual(UnitConverter.lbsFrom(kg: 0), 0, accuracy: 0.000001)
    }

    func test_lbsFrom_large_value() {
        XCTAssertEqual(UnitConverter.lbsFrom(kg: 1000), 2204.623, accuracy: 0.001)
    }

    // MARK: - Round-trip kg ↔ lbs

    func test_roundtrip_lbs_to_kg_and_back() {
        let original = 175.0
        let converted = UnitConverter.lbsFrom(kg: UnitConverter.kgFrom(lbs: original))
        XCTAssertEqual(converted, original, accuracy: 0.000001)
    }

    func test_roundtrip_kg_to_lbs_and_back() {
        let original = 80.0
        let converted = UnitConverter.kgFrom(lbs: UnitConverter.lbsFrom(kg: original))
        XCTAssertEqual(converted, original, accuracy: 0.000001)
    }

    // MARK: - litresFrom(oz:)

    func test_litresFrom_known_value_one_oz() {
        XCTAssertEqual(UnitConverter.litresFrom(oz: 1), 0.0295735296, accuracy: 0.0000001)
    }

    func test_litresFrom_zero_returns_zero() {
        XCTAssertEqual(UnitConverter.litresFrom(oz: 0), 0, accuracy: 0.0000001)
    }

    func test_litresFrom_84point5_oz_is_approximately_2point5_litres() {
        // 84.5 fl oz ≈ 2.499 L — a typical daily water target
        XCTAssertEqual(UnitConverter.litresFrom(oz: 84.5), 2.499, accuracy: 0.001)
    }

    func test_litresFrom_large_value() {
        XCTAssertEqual(UnitConverter.litresFrom(oz: 1000), 29.5735296, accuracy: 0.0001)
    }

    // MARK: - ozFrom(litres:)

    func test_ozFrom_known_value_one_litre() {
        XCTAssertEqual(UnitConverter.ozFrom(litres: 1), 33.814, accuracy: 0.001)
    }

    func test_ozFrom_zero_returns_zero() {
        XCTAssertEqual(UnitConverter.ozFrom(litres: 0), 0, accuracy: 0.0000001)
    }

    func test_ozFrom_large_value() {
        XCTAssertEqual(UnitConverter.ozFrom(litres: 10), 338.14, accuracy: 0.01)
    }

    // MARK: - Round-trip oz ↔ litres

    func test_roundtrip_oz_to_litres_and_back() {
        let original = 64.0
        let converted = UnitConverter.ozFrom(litres: UnitConverter.litresFrom(oz: original))
        XCTAssertEqual(converted, original, accuracy: 0.000001)
    }

    func test_roundtrip_litres_to_oz_and_back() {
        let original = 2.5
        let converted = UnitConverter.litresFrom(oz: UnitConverter.ozFrom(litres: original))
        XCTAssertEqual(converted, original, accuracy: 0.000001)
    }
}
