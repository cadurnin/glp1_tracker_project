import Foundation

struct PatternInsight: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let isNew: Bool
}

struct SymptomPatternAnalyzer {
    func analyze(checkIns: [DailyCheckIn], injectionLogs: [InjectionLog]) -> [PatternInsight] {
        guard checkIns.count >= 2 else { return [] }

        var insights: [PatternInsight] = []
        let sorted = checkIns.sorted { $0.date < $1.date }
        let last7 = Array(sorted.suffix(7))
        let last14 = Array(sorted.suffix(14))
        let last30 = Array(sorted.suffix(30))

        // Frequency alerts: appeared 5+ out of last 7 days
        for symptom in SymptomList.all {
            let count = last7.filter { day in
                day.symptoms.contains { $0.symptomId == symptom.id && $0.present }
            }.count
            if count >= 5 {
                insights.append(PatternInsight(
                    title: "Frequent \(symptom.name)",
                    detail: "You have experienced \(symptom.name.lowercased()) \(count) out of the last 7 days.",
                    isNew: false
                ))
            }
        }

        // Severity escalation: severity in last 14 days
        for symptom in SymptomList.all where symptom.tracksSeverity {
            let entries = last14.flatMap(\.symptoms).filter { $0.symptomId == symptom.id && $0.present && $0.severity != nil }
            guard entries.count >= 4 else { continue }
            let half = entries.count / 2
            let firstHalf = Array(entries.prefix(half))
            let secondHalf = Array(entries.suffix(half))
            let avg1 = firstHalf.compactMap(\.severity).map(Double.init).reduce(0, +) / Double(firstHalf.count)
            let avg2 = secondHalf.compactMap(\.severity).map(Double.init).reduce(0, +) / Double(secondHalf.count)
            if avg2 - avg1 >= 1.0 {
                insights.append(PatternInsight(
                    title: "\(symptom.name) getting worse",
                    detail: String(format: "Your \(symptom.name.lowercased()) severity has increased (avg %.1f → %.1f) over the past 2 weeks.", avg1, avg2),
                    isNew: false
                ))
            }
        }

        // New symptom detection
        for symptom in SymptomList.all {
            let recentPresent = last7.contains { day in
                day.symptoms.contains { $0.symptomId == symptom.id && $0.present }
            }
            guard recentPresent else { continue }
            let olderDays = sorted.dropLast(7)
            let lastSeen = olderDays.last(where: { day in
                day.symptoms.contains { $0.symptomId == symptom.id && $0.present }
            })?.date
            if lastSeen == nil {
                insights.append(PatternInsight(
                    title: "New symptom: \(symptom.name)",
                    detail: "You reported \(symptom.name.lowercased()) for the first time this week.",
                    isNew: true
                ))
            } else if let d = lastSeen, Date().timeIntervalSince(d) > 14 * 86400 {
                insights.append(PatternInsight(
                    title: "\(symptom.name) returned",
                    detail: "\(symptom.name) has returned after 14+ days of absence.",
                    isNew: true
                ))
            }
        }

        // Cycle correlation: symptom peaks on specific cycle days
        let cycleDayGroups = Dictionary(grouping: sorted) { $0.cycleDay }
        for symptom in SymptomList.all {
            var dayFrequency: [Int: (present: Int, total: Int)] = [:]
            for (day, days) in cycleDayGroups {
                let present = days.filter { d in d.symptoms.contains { $0.symptomId == symptom.id && $0.present } }.count
                dayFrequency[day] = (present, days.count)
            }
            if let peak = dayFrequency.max(by: { a, b in
                let rateA = Double(a.value.present) / Double(max(1, a.value.total))
                let rateB = Double(b.value.present) / Double(max(1, b.value.total))
                return rateA < rateB
            }) {
                let rate = Double(peak.value.present) / Double(max(1, peak.value.total))
                if rate >= 0.7 && peak.value.total >= 3 {
                    insights.append(PatternInsight(
                        title: "\(symptom.name) peaks on Day \(peak.key)",
                        detail: "Your \(symptom.name.lowercased()) is most frequent on Day \(peak.key) of your injection cycle.",
                        isNew: false
                    ))
                }
            }
        }

        // Dose increase correlation: did symptoms worsen after last dose increase?
        if let latestLog = injectionLogs.sorted(by: { $0.date < $1.date }).last {
            let postDose = last30.filter { $0.date > latestLog.date }
            let preDose = last30.filter { $0.date < latestLog.date }
            if postDose.count >= 3 && preDose.count >= 3 {
                let countSymptoms: ([DailyCheckIn]) -> Double = { days in
                    Double(days.flatMap(\.symptoms).filter(\.present).count) / Double(days.count)
                }
                let pre = countSymptoms(preDose)
                let post = countSymptoms(postDose)
                if post - pre >= 1.5 {
                    insights.append(PatternInsight(
                        title: "More symptoms after dose change",
                        detail: "Your symptom frequency has increased since your last dose change on \(latestLog.date.formatted(.dateTime.month().day())).",
                        isNew: false
                    ))
                }
            }
        }

        return insights
    }
}
