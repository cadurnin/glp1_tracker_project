import XCTest
@testable import GLP1Tracker

final class HeartRateAnalyzerTests: XCTestCase {

    // MARK: - Helpers

    private func makeReadings(bpms: [Double]) -> [DailyHeartRate] {
        bpms.enumerated().map { index, bpm in
            DailyHeartRate(date: Date(timeIntervalSince1970: Double(index) * 86400), bpm: bpm)
        }
    }

    // MARK: - Insufficient data

    func test_analyze_empty_input_returns_hasEnoughData_false() {
        let result = HeartRateAnalyzer.analyze([])
        XCTAssertFalse(result.hasEnoughData)
    }

    func test_analyze_fewer_than_7_readings_returns_hasEnoughData_false() {
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: [60, 62, 65, 70, 68]))
        XCTAssertFalse(result.hasEnoughData)
    }

    func test_analyze_exactly_6_readings_returns_hasEnoughData_false() {
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: [60, 62, 65, 70, 68, 66]))
        XCTAssertFalse(result.hasEnoughData)
    }

    func test_analyze_fewer_than_7_returns_all_zero_stats() {
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: [60, 65]))
        XCTAssertEqual(result.ninetyDayMean, 0)
        XCTAssertEqual(result.standardDeviation, 0)
        XCTAssertEqual(result.upperThreshold, 0)
        XCTAssertEqual(result.lowerThreshold, 0)
        XCTAssertEqual(result.sevenDayAverage, 0)
        XCTAssertTrue(result.outliers.isEmpty)
    }

    // MARK: - Enough data

    func test_analyze_7_readings_returns_hasEnoughData_true() {
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: [60, 62, 64, 66, 68, 70, 72]))
        XCTAssertTrue(result.hasEnoughData)
    }

    // MARK: - Mean calculation

    func test_analyze_mean_is_correct_for_uniform_values() {
        let readings = makeReadings(bpms: Array(repeating: 70.0, count: 10))
        let result = HeartRateAnalyzer.analyze(readings)
        XCTAssertEqual(result.ninetyDayMean, 70.0, accuracy: 0.0001)
    }

    func test_analyze_mean_is_correct_for_known_values() {
        // Mean of [60, 70, 80, 90, 100, 60, 70] = 530/7 ≈ 75.714
        let readings = makeReadings(bpms: [60, 70, 80, 90, 100, 60, 70])
        let result = HeartRateAnalyzer.analyze(readings)
        XCTAssertEqual(result.ninetyDayMean, 530.0 / 7.0, accuracy: 0.0001)
    }

    // MARK: - Standard deviation

    func test_analyze_stddev_is_zero_for_uniform_values() {
        let readings = makeReadings(bpms: Array(repeating: 72.0, count: 10))
        let result = HeartRateAnalyzer.analyze(readings)
        XCTAssertEqual(result.standardDeviation, 0, accuracy: 0.0001)
    }

    func test_analyze_stddev_is_positive_for_varied_values() {
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: [60, 70, 80, 90, 100, 60, 70]))
        XCTAssertGreaterThan(result.standardDeviation, 0)
    }

    // MARK: - Thresholds

    func test_analyze_upper_threshold_is_mean_plus_two_stddevs() {
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: [60, 70, 80, 90, 100, 60, 70]))
        let expected = result.ninetyDayMean + 2.0 * result.standardDeviation
        XCTAssertEqual(result.upperThreshold, expected, accuracy: 0.0001)
    }

    func test_analyze_lower_threshold_is_mean_minus_two_stddevs() {
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: [60, 70, 80, 90, 100, 60, 70]))
        let expected = result.ninetyDayMean - 2.0 * result.standardDeviation
        XCTAssertEqual(result.lowerThreshold, expected, accuracy: 0.0001)
    }

    // MARK: - Seven-day average

    func test_analyze_seven_day_average_uses_last_7_readings() {
        // First 3 readings are low; last 7 are all 80 — the average should be 80
        let bpms = [50.0, 50.0, 50.0] + Array(repeating: 80.0, count: 7)
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: bpms))
        XCTAssertEqual(result.sevenDayAverage, 80.0, accuracy: 0.0001)
    }

    func test_analyze_seven_day_average_equals_mean_when_exactly_7_readings() {
        let readings = makeReadings(bpms: [60, 70, 80, 90, 100, 60, 70])
        let result = HeartRateAnalyzer.analyze(readings)
        XCTAssertEqual(result.sevenDayAverage, result.ninetyDayMean, accuracy: 0.0001)
    }

    // MARK: - Outliers

    func test_analyze_no_outliers_for_uniform_data() {
        let readings = makeReadings(bpms: Array(repeating: 72.0, count: 10))
        let result = HeartRateAnalyzer.analyze(readings)
        XCTAssertTrue(result.outliers.isEmpty)
    }

    func test_analyze_single_high_spike_is_detected_as_outlier() {
        // Readings are all 70, except one extreme spike
        var bpms = Array(repeating: 70.0, count: 29)
        bpms.append(200.0)  // extreme outlier
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: bpms))
        XCTAssertFalse(result.outliers.isEmpty)
        XCTAssertTrue(result.outliers.contains { $0.bpm == 200.0 })
    }

    func test_analyze_single_low_dip_is_detected_as_outlier() {
        var bpms = Array(repeating: 70.0, count: 29)
        bpms.append(10.0)  // extreme low outlier
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: bpms))
        XCTAssertFalse(result.outliers.isEmpty)
        XCTAssertTrue(result.outliers.contains { $0.bpm == 10.0 })
    }

    func test_analyze_monotonically_increasing_values_produces_no_outliers() {
        // Slowly increasing values — no single point is far from the mean
        let bpms = (60..<70).map { Double($0) }
        let result = HeartRateAnalyzer.analyze(makeReadings(bpms: bpms))
        XCTAssertTrue(result.outliers.isEmpty)
    }
}
