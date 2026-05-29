import Foundation

struct CSVExporter {
    /// Exports check-in records to a CSV-formatted string with metadata and symptoms.
    /// Sorts check-ins by date ascending and includes all symptoms from SymptomList as columns.
    /// Symptoms with severity show "Yes (n/5)" where n is the severity level.
    /// - Parameters:
    ///   - checkIns: Array of DailyCheckIn records to export.
    /// - Returns: CSV string with header and rows separated by newlines. Empty array produces header only.
    static func export(checkIns: [DailyCheckIn]) -> String {
        let headerMeta = ["Date", "Overall Score", "Weight (kg)", "Water (L)", "Cycle Day", "Injection Day"]
        let headerSymptoms = SymptomList.all.map { $0.name }
        let header = (headerMeta + headerSymptoms).joined(separator: ",")

        let rows = checkIns.sorted { $0.date < $1.date }.map { c -> String in
            let dateStr = c.date.formatted(date: .numeric, time: .omitted)
            let score = "\(c.overallScore)"
            let weight = c.weightKg.map { String(format: "%.2f", $0) } ?? ""
            let water = c.waterLitres.map { String(format: "%.2f", $0) } ?? ""
            let cycleDay = "\(c.cycleDay)"
            let injectionDay = c.injectionLogId != nil ? "Yes" : "No"

            let meta = [dateStr, score, weight, water, cycleDay, injectionDay]

            let symptoms = SymptomList.all.map { symptom -> String in
                guard let entry = c.symptoms.first(where: { $0.symptomId == symptom.id }) else { return "No" }
                if !entry.present { return "No" }
                if let sev = entry.severity { return "Yes (\(sev)/5)" }
                return "Yes"
            }

            return (meta + symptoms).joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }
}
