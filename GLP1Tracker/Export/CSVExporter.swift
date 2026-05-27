import SwiftUI
import UIKit

struct CSVExporter {
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

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
