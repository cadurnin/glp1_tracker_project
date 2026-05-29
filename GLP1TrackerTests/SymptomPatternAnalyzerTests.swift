import XCTest
@testable import GLP1Tracker

final class SymptomPatternAnalyzerTests: XCTestCase {

    // MARK: - Helpers

    private func makeCheckIn(
        daysAgo: Int,
        symptomIds: [String] = [],
        severities: [String: Int] = [:],
        injectionLogId: UUID? = nil
    ) -> DailyCheckIn {
        let date = Date(timeIntervalSinceNow: -Double(daysAgo) * 86400)
        let checkIn = DailyCheckIn(
            date: date,
            injectionLogId: injectionLogId
        )
        let id = checkIn.id
        checkIn.symptoms = SymptomList.all.map { symptom in
            let present = symptomIds.contains(symptom.id)
            return SymptomEntry(
                symptomId: symptom.id,
                present: present,
                severity: (present && symptom.tracksSeverity) ? (severities[symptom.id] ?? 1) : nil,
                date: date,
                checkInId: id
            )
        }
        return checkIn
    }

    // MARK: - Minimum data guard

    func test_analyze_returns_empty_for_fewer_than_7_check_ins() {
        let checkIns = (0..<6).map { makeCheckIn(daysAgo: $0) }
        XCTAssertTrue(SymptomPatternAnalyzer.analyze(checkIns: checkIns).isEmpty)
    }

    func test_analyze_returns_empty_for_empty_input() {
        XCTAssertTrue(SymptomPatternAnalyzer.analyze(checkIns: []).isEmpty)
    }

    // MARK: - Frequency insights

    func test_analyze_frequency_insight_fires_when_symptom_appears_in_7_of_7_days() {
        // nausea present every day for 7 days → rate = 100% ≥ 70%
        let checkIns = (0..<7).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"]) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let titles = insights.map { $0.title }
        XCTAssertTrue(titles.contains("Frequent: Nausea"))
    }

    func test_analyze_frequency_insight_fires_when_symptom_appears_in_5_of_7_days() {
        // 5/7 ≈ 71% ≥ 70%
        var checkIns = (0..<5).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"]) }
        checkIns += (5..<7).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let titles = insights.map { $0.title }
        XCTAssertTrue(titles.contains("Frequent: Nausea"))
    }

    func test_analyze_no_frequency_insight_when_symptom_appears_in_4_of_7_days() {
        // 4/7 ≈ 57% < 70%
        var checkIns = (0..<4).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"]) }
        checkIns += (4..<7).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let titles = insights.map { $0.title }
        XCTAssertFalse(titles.contains("Frequent: Nausea"))
    }

    func test_analyze_frequency_insight_symbol_is_correct() {
        let checkIns = (0..<7).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"]) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let frequencyInsight = insights.first { $0.title == "Frequent: Nausea" }
        XCTAssertEqual(frequencyInsight?.symbolName, "repeat.circle.fill")
    }

    // MARK: - New symptom insights

    func test_analyze_new_symptom_insight_fires_when_symptom_appears_only_in_last_3_days() {
        // Requires at least 8 check-ins; headache appears only in the 3 most recent
        let previous = (3..<10).map { makeCheckIn(daysAgo: $0, symptomIds: []) }
        let recent = (0..<3).map { makeCheckIn(daysAgo: $0, symptomIds: ["headache"]) }
        let checkIns = previous + recent
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let titles = insights.map { $0.title }
        XCTAssertTrue(titles.contains("New Symptom"))
    }

    func test_analyze_no_new_symptom_insight_when_symptom_also_appeared_in_previous_days() {
        // headache present in both old and recent data — not a new symptom
        let previous = (3..<10).map { makeCheckIn(daysAgo: $0, symptomIds: ["headache"]) }
        let recent = (0..<3).map { makeCheckIn(daysAgo: $0, symptomIds: ["headache"]) }
        let checkIns = previous + recent
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let newSymptomInsights = insights.filter { $0.title == "New Symptom" }
        XCTAssertTrue(newSymptomInsights.isEmpty)
    }

    func test_analyze_new_symptom_insight_requires_at_least_8_check_ins() {
        // Only 7 check-ins — newSymptomInsights requires >= 8, so no new-symptom insight
        let checkIns = (0..<7).map { makeCheckIn(daysAgo: $0, symptomIds: $0 < 3 ? ["headache"] : []) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let newSymptomInsights = insights.filter { $0.title == "New Symptom" }
        XCTAssertTrue(newSymptomInsights.isEmpty)
    }

    func test_analyze_new_symptom_insight_symbol_is_correct() {
        let previous = (3..<10).map { makeCheckIn(daysAgo: $0, symptomIds: []) }
        let recent = (0..<3).map { makeCheckIn(daysAgo: $0, symptomIds: ["headache"]) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: previous + recent)
        let newInsight = insights.first { $0.title == "New Symptom" }
        XCTAssertEqual(newInsight?.symbolName, "exclamationmark.circle.fill")
    }

    // MARK: - Severity trend insights

    func test_analyze_worsening_severity_insight_fires_when_recent_average_is_more_than_1_above_old() {
        // Nausea: old severities = [1, 1], recent severities = [4, 4, 4]
        // oldAvg = 1, recentAvg = 4 → difference > 1 → worsening
        var checkIns: [DailyCheckIn] = []
        checkIns += (7..<9).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"], severities: ["nausea": 1]) }
        checkIns += (0..<3).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"], severities: ["nausea": 4]) }
        // Pad to ≥ 7 total
        checkIns += (9..<11).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let titles = insights.map { $0.title }
        XCTAssertTrue(titles.contains("Nausea Worsening"))
    }

    func test_analyze_improving_severity_insight_fires_when_recent_average_is_more_than_1_below_old() {
        // Nausea: old severities = [4, 4], recent = [1, 1, 1]
        var checkIns: [DailyCheckIn] = []
        checkIns += (7..<9).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"], severities: ["nausea": 4]) }
        checkIns += (0..<3).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"], severities: ["nausea": 1]) }
        checkIns += (9..<11).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let titles = insights.map { $0.title }
        XCTAssertTrue(titles.contains("Nausea Improving"))
    }

    func test_analyze_no_severity_trend_when_change_is_exactly_1() {
        // oldAvg = 2, recentAvg = 3 → difference = 1.0, which is NOT > 1 → no insight
        var checkIns: [DailyCheckIn] = []
        checkIns += (7..<9).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"], severities: ["nausea": 2]) }
        checkIns += (0..<3).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"], severities: ["nausea": 3]) }
        checkIns += (9..<11).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let titles = insights.map { $0.title }
        XCTAssertFalse(titles.contains("Nausea Worsening"))
        XCTAssertFalse(titles.contains("Nausea Improving"))
    }

    func test_analyze_worsening_severity_symbol_is_correct() {
        var checkIns: [DailyCheckIn] = []
        checkIns += (7..<9).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"], severities: ["nausea": 1]) }
        checkIns += (0..<3).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"], severities: ["nausea": 4]) }
        checkIns += (9..<11).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let worseningInsight = insights.first { $0.title == "Nausea Worsening" }
        XCTAssertEqual(worseningInsight?.symbolName, "arrow.up.circle.fill")
    }

    func test_analyze_improving_severity_symbol_is_correct() {
        var checkIns: [DailyCheckIn] = []
        checkIns += (7..<9).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"], severities: ["nausea": 4]) }
        checkIns += (0..<3).map { makeCheckIn(daysAgo: $0, symptomIds: ["nausea"], severities: ["nausea": 1]) }
        checkIns += (9..<11).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: checkIns)
        let improvingInsight = insights.first { $0.title == "Nausea Improving" }
        XCTAssertEqual(improvingInsight?.symbolName, "arrow.down.circle.fill")
    }

    // MARK: - Cycle day insights

    func test_analyze_injection_day_pattern_fires_when_3_injection_days_each_have_3_or_more_symptoms() {
        // 3 injection-day check-ins each with 3+ symptoms, plus enough non-injection days
        let injectionDays = (0..<3).map {
            makeCheckIn(
                daysAgo: $0 * 7,
                symptomIds: ["nausea", "vomiting", "diarrhea"],
                injectionLogId: UUID()
            )
        }
        let padding = (1..<7).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: injectionDays + padding)
        let titles = insights.map { $0.title }
        XCTAssertTrue(titles.contains("Injection Day Pattern"))
    }

    func test_analyze_no_injection_day_pattern_when_fewer_than_3_injection_days() {
        let injectionDays = (0..<2).map {
            makeCheckIn(
                daysAgo: $0 * 7,
                symptomIds: ["nausea", "vomiting", "diarrhea"],
                injectionLogId: UUID()
            )
        }
        let padding = (1..<6).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: injectionDays + padding)
        let titles = insights.map { $0.title }
        XCTAssertFalse(titles.contains("Injection Day Pattern"))
    }

    func test_analyze_no_injection_day_pattern_when_average_symptoms_is_below_3() {
        // Injection days have only 1 symptom each → avg < 3
        let injectionDays = (0..<3).map {
            makeCheckIn(
                daysAgo: $0 * 7,
                symptomIds: ["nausea"],
                injectionLogId: UUID()
            )
        }
        let padding = (1..<7).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: injectionDays + padding)
        let titles = insights.map { $0.title }
        XCTAssertFalse(titles.contains("Injection Day Pattern"))
    }

    func test_analyze_injection_day_pattern_symbol_is_correct() {
        let injectionDays = (0..<3).map {
            makeCheckIn(
                daysAgo: $0 * 7,
                symptomIds: ["nausea", "vomiting", "diarrhea"],
                injectionLogId: UUID()
            )
        }
        let padding = (1..<7).map { makeCheckIn(daysAgo: $0) }
        let insights = SymptomPatternAnalyzer.analyze(checkIns: injectionDays + padding)
        let patternInsight = insights.first { $0.title == "Injection Day Pattern" }
        XCTAssertEqual(patternInsight?.symbolName, "syringe.fill")
    }
}
