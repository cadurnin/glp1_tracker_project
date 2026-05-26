import Foundation
import SwiftData
import UIKit

struct CSVExporter {
    static let header = """
    Date,CycleDay,Weight(kg),Water(L),OverallScore,RestingHR,SleepHours,SleepREM,SleepDeep,DoseMg,InjectionDay,\
    Nausea_Present,Nausea_Severity,Vomiting_Present,Vomiting_Severity,Diarrhea_Present,Constipation_Present,\
    Constipation_Severity,Indigestion_Present,AbdominalPain_Present,AbdominalPain_Severity,Fatigue_Present,\
    Fatigue_Severity,Headache_Present,Headache_Severity,AppetiteLoss_Present,Bloating_Present,DarkUrine_Present,\
    InfrequentUrination_Present,Dizziness_Present,AcidReflux_Present,BrainFog_Present,UpperStomachPain_Present,\
    Jaundice_Present,AbdominalPainRadiating_Present,AbsoluteConstipation_Present,ExtremeBloating_Present,\
    NeckLump_Present,Hoarseness_Present,TroubleSwallowing_Present,ShortnessOfBreath_Present,RapidHeartRate_Present,\
    MoodChanges_Present,HypoglycemiaSymptoms_Present,VisionChanges_Present,HairLoss_Present,InjectionSiteReaction_Present,Notes
    """

    func export(checkIns: [DailyCheckIn], snapshots: [HealthSnapshot], injectionLogs: [InjectionLog]) -> URL? {
        var rows: [String] = [Self.header]

        let snapshotByDate = Dictionary(uniqueKeysWithValues: snapshots.map {
            (Calendar.current.startOfDay(for: $0.date), $0)
        })
        let injectionByDate = Dictionary(uniqueKeysWithValues: injectionLogs.map {
            (Calendar.current.startOfDay(for: $0.date), $0)
        })

        let sorted = checkIns.sorted { $0.date < $1.date }
        for checkIn in sorted {
            let dayKey = Calendar.current.startOfDay(for: checkIn.date)
            let snap = snapshotByDate[dayKey]
            let injection = injectionByDate[dayKey]

            func symptomPresent(_ id: String) -> String {
                (checkIn.symptoms.first { $0.symptomId == id }?.present ?? false) ? "1" : "0"
            }
            func symptomSeverity(_ id: String) -> String {
                guard let s = checkIn.symptoms.first(where: { $0.symptomId == id }), s.present, let sev = s.severity else { return "" }
                return "\(sev)"
            }

            // Break into chunks so the compiler can type-check each independently
            let meta: [String] = [
                checkIn.date.formatted(.iso8601.year().month().day()),
                "\(checkIn.cycleDay)",
                checkIn.weightKg.map { String(format: "%.2f", $0) } ?? "",
                checkIn.waterLitres.map { String(format: "%.2f", $0) } ?? "",
                "\(checkIn.overallScore)"
            ]
            let health: [String] = [
                snap?.restingHeartRate.map { String(format: "%.0f", $0) } ?? "",
                snap?.sleepHours.map { String(format: "%.2f", $0) } ?? "",
                snap?.sleepREM.map { String(format: "%.2f", $0) } ?? "",
                snap?.sleepDeep.map { String(format: "%.2f", $0) } ?? "",
                injection.map { String(format: "%.2f", $0.doseMg) } ?? "",
                injection != nil ? "1" : "0"
            ]
            let commonSymptoms: [String] = [
                symptomPresent("nausea"),       symptomSeverity("nausea"),
                symptomPresent("vomiting"),     symptomSeverity("vomiting"),
                symptomPresent("diarrhea"),
                symptomPresent("constipation"), symptomSeverity("constipation"),
                symptomPresent("indigestion"),
                symptomPresent("abdominal_pain_general"), symptomSeverity("abdominal_pain_general"),
                symptomPresent("fatigue"),      symptomSeverity("fatigue"),
                symptomPresent("headache"),     symptomSeverity("headache"),
                symptomPresent("appetite_loss"),
                symptomPresent("bloating")
            ]
            let rareSymptoms: [String] = [
                symptomPresent("dark_urine"),
                symptomPresent("infrequent_urination"),
                symptomPresent("dizziness"),
                symptomPresent("acid_reflux"),
                symptomPresent("brain_fog"),
                symptomPresent("upper_stomach_pain"),
                symptomPresent("jaundice"),
                symptomPresent("abdominal_pain_radiating"),
                symptomPresent("absolute_constipation"),
                symptomPresent("extreme_bloating"),
                symptomPresent("neck_lump"),
                symptomPresent("hoarseness"),
                symptomPresent("trouble_swallowing"),
                symptomPresent("shortness_of_breath"),
                symptomPresent("rapid_heart_rate"),
                symptomPresent("mood_changes"),
                symptomPresent("hypoglycemia_symptoms"),
                symptomPresent("vision_changes"),
                symptomPresent("hair_loss"),
                symptomPresent("injection_site_reaction"),
                ""
            ]
            let row = (meta + health + commonSymptoms + rareSymptoms).joined(separator: ",")
            rows.append(row)
        }

        let csv = rows.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GLP1Tracker_Export_\(Date().formatted(.iso8601.year().month().day())).csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    func share(url: URL, from scene: UIWindowScene? = nil) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        let presenter = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        presenter?.present(vc, animated: true)
    }
}
