import XCTest
@testable import GLP1Tracker

final class OutlierDetectorTests: XCTestCase {

    // MARK: - Helpers

    private func makeCheckIn(
        date: Date,
        score: Int = 5,
        weightKg: Double? = nil,
        waterLitres: Double? = nil,
        injectionLogId: UUID? = nil
    ) -> DailyCheckIn {
        DailyCheckIn(
            date: date,
            weightKg: weightKg,
            waterLitres: waterLitres,
            overallScore: score,
            injectionLogId: injectionLogId
        )
    }

    /// Returns `count` check-ins spaced one day apart starting from epoch zero,
    /// with the given score and optional weight/water.
    private func makeCheckIns(
        count: Int,
        score: Int = 5,
        weightKg: Double? = 70.0,
        waterLitres: Double? = 2.0
    ) -> [DailyCheckIn] {
        (0..<count).map { i in
            makeCheckIn(
                date: Date(timeIntervalSince1970: Double(i) * 86400),
                score: score,
                weightKg: weightKg,
                waterLitres: waterLitres
            )
        }
    }

    // MARK: - Minimum data guard

    func test_detect_returns_empty_for_fewer_than_7_check_ins() {
        let checkIns = makeCheckIns(count: 6)
        XCTAssertTrue(OutlierDetector.detect(checkIns: checkIns).isEmpty)
    }

    func test_detect_returns_empty_for_zero_check_ins() {
        XCTAssertTrue(OutlierDetector.detect(checkIns: []).isEmpty)
    }

    func test_detect_accepts_exactly_7_check_ins_without_crashing() {
        let checkIns = makeCheckIns(count: 7)
        // Should not crash — result count doesn't matter here
        _ = OutlierDetector.detect(checkIns: checkIns)
    }

    // MARK: - Uniform data produces no insights

    func test_detect_no_outliers_when_all_scores_are_identical() {
        // Identical scores → std dev = 0 → zScoreInsights returns [] early
        let checkIns = makeCheckIns(count: 10, score: 5, weightKg: nil, waterLitres: nil)
        let insights = OutlierDetector.detect(checkIns: checkIns)
        XCTAssertTrue(insights.isEmpty)
    }

    func test_detect_no_outliers_when_all_weights_are_identical() {
        // Uniform weight velocities (all zero) → sd = 0 → no outliers
        let checkIns = makeCheckIns(count: 10, score: 5, weightKg: 70.0, waterLitres: nil)
        let insights = OutlierDetector.detect(checkIns: checkIns)
        XCTAssertTrue(insights.isEmpty)
    }

    // MARK: - Score outlier detection

    func test_detect_flags_unusually_high_score_in_recent_data() {
        // 9 check-ins at score 5, plus one at score 100 (extreme outlier) at the end
        var checkIns = makeCheckIns(count: 9, score: 5, weightKg: nil, waterLitres: nil)
        checkIns.append(makeCheckIn(
            date: Date(timeIntervalSince1970: Double(9) * 86400),
            score: 100,
            weightKg: nil,
            waterLitres: nil
        ))
        let insights = OutlierDetector.detect(checkIns: checkIns)
        let scoreTitles = insights.map { $0.title }
        XCTAssertTrue(scoreTitles.contains("Wellbeing Score"))
    }

    func test_detect_flags_unusually_low_score_in_recent_data() {
        // 9 check-ins at score 8, plus one at score 1 (very low) at the end
        var checkIns = makeCheckIns(count: 9, score: 8, weightKg: nil, waterLitres: nil)
        checkIns.append(makeCheckIn(
            date: Date(timeIntervalSince1970: Double(9) * 86400),
            score: 1,
            weightKg: nil,
            waterLitres: nil
        ))
        let insights = OutlierDetector.detect(checkIns: checkIns)
        let scoreTitles = insights.map { $0.title }
        XCTAssertTrue(scoreTitles.contains("Wellbeing Score"))
    }

    func test_detect_high_score_outlier_has_up_trend() {
        var checkIns = makeCheckIns(count: 9, score: 5, weightKg: nil, waterLitres: nil)
        checkIns.append(makeCheckIn(
            date: Date(timeIntervalSince1970: Double(9) * 86400),
            score: 100,
            weightKg: nil,
            waterLitres: nil
        ))
        let insights = OutlierDetector.detect(checkIns: checkIns)
        let scoreInsight = insights.first { $0.title == "Wellbeing Score" }
        XCTAssertEqual(scoreInsight?.trend, .up)
    }

    func test_detect_low_score_outlier_has_down_trend() {
        var checkIns = makeCheckIns(count: 9, score: 8, weightKg: nil, waterLitres: nil)
        checkIns.append(makeCheckIn(
            date: Date(timeIntervalSince1970: Double(9) * 86400),
            score: 1,
            weightKg: nil,
            waterLitres: nil
        ))
        let insights = OutlierDetector.detect(checkIns: checkIns)
        let scoreInsight = insights.first { $0.title == "Wellbeing Score" }
        XCTAssertEqual(scoreInsight?.trend, .down)
    }

    // MARK: - Water outlier detection

    func test_detect_flags_unusually_low_water_in_recent_data() {
        // 9 check-ins at 2.0 L, plus one at nearly zero at the end
        var checkIns = makeCheckIns(count: 9, score: 5, weightKg: nil, waterLitres: 2.0)
        checkIns.append(makeCheckIn(
            date: Date(timeIntervalSince1970: Double(9) * 86400),
            score: 5,
            weightKg: nil,
            waterLitres: 0.01
        ))
        let insights = OutlierDetector.detect(checkIns: checkIns)
        let titles = insights.map { $0.title }
        XCTAssertTrue(titles.contains("Water Intake"))
    }

    func test_detect_low_water_outlier_has_down_trend() {
        var checkIns = makeCheckIns(count: 9, score: 5, weightKg: nil, waterLitres: 2.0)
        checkIns.append(makeCheckIn(
            date: Date(timeIntervalSince1970: Double(9) * 86400),
            score: 5,
            weightKg: nil,
            waterLitres: 0.01
        ))
        let insights = OutlierDetector.detect(checkIns: checkIns)
        let waterInsight = insights.first { $0.title == "Water Intake" }
        XCTAssertEqual(waterInsight?.trend, .down)
    }

    // MARK: - Weight outlier detection

    func test_detect_flags_unusual_weight_velocity_in_recent_data() {
        // 9 check-ins with tiny weight changes, then a sudden extreme drop
        var checkIns: [DailyCheckIn] = (0..<9).map { i in
            makeCheckIn(
                date: Date(timeIntervalSince1970: Double(i) * 86400),
                score: 5,
                weightKg: 70.0 + Double(i) * 0.01  // ~0.01 kg/day
            )
        }
        // Final check-in with an extreme weight drop (large negative velocity)
        checkIns.append(makeCheckIn(
            date: Date(timeIntervalSince1970: Double(9) * 86400),
            score: 5,
            weightKg: 50.0
        ))
        let insights = OutlierDetector.detect(checkIns: checkIns)
        let titles = insights.map { $0.title }
        XCTAssertTrue(titles.contains("Weight Change"))
    }

    // MARK: - OutlierInsight properties

    func test_detect_insight_date_is_set() {
        var checkIns = makeCheckIns(count: 9, score: 5, weightKg: nil, waterLitres: nil)
        checkIns.append(makeCheckIn(
            date: Date(timeIntervalSince1970: Double(9) * 86400),
            score: 100
        ))
        let insights = OutlierDetector.detect(checkIns: checkIns)
        XCTAssertFalse(insights.isEmpty)
        XCTAssertNotNil(insights.first?.date)
    }

    func test_detect_insight_message_is_non_empty() {
        var checkIns = makeCheckIns(count: 9, score: 5, weightKg: nil, waterLitres: nil)
        checkIns.append(makeCheckIn(
            date: Date(timeIntervalSince1970: Double(9) * 86400),
            score: 100
        ))
        let insights = OutlierDetector.detect(checkIns: checkIns)
        XCTAssertFalse(insights.isEmpty)
        XCTAssertFalse(insights.first?.message.isEmpty ?? true)
    }

    // MARK: - Only recent data is flagged

    func test_detect_only_examines_last_3_data_points_for_outliers() {
        // Put the outlier at position 0 (oldest) — should not appear in insights.
        // Positions 1–9 are uniform, making position 0 a statistical outlier by z-score,
        // but zScoreInsights only reports from suffix(3), so no insight should fire
        // for a value that is only extreme at the beginning.
        var checkIns: [DailyCheckIn] = [
            makeCheckIn(
                date: Date(timeIntervalSince1970: 0),
                score: 100,  // extreme — but oldest, not in suffix(3)
                weightKg: nil,
                waterLitres: nil
            )
        ]
        checkIns += (1..<10).map { i in
            makeCheckIn(
                date: Date(timeIntervalSince1970: Double(i) * 86400),
                score: 5,
                weightKg: nil,
                waterLitres: nil
            )
        }
        let insights = OutlierDetector.detect(checkIns: checkIns)
        // The extreme value is in the past, not in the last 3, so score should not be flagged
        let scoreInsights = insights.filter { $0.title == "Wellbeing Score" }
        XCTAssertTrue(scoreInsights.isEmpty)
    }
}
