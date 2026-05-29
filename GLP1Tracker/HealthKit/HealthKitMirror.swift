import Foundation

struct HealthKitMirror {
    /// Reads HealthKit data and check-in fields to produce a HealthSnapshot.
    /// Async reads are performed first; symptom mapping is delegated to `applySymptoms`.
    static func buildSnapshot(for date: Date, checkIn: DailyCheckIn) async -> HealthSnapshot {
        let snapshot = HealthSnapshot(date: date)

        snapshot.restingHeartRate = await HeartRateReader.readRestingHeartRate(for: date)

        if let sleep = await SleepReader.readSleep(for: date) {
            snapshot.sleepHours = sleep.totalHours
            snapshot.sleepREM = sleep.remHours
            snapshot.sleepDeep = sleep.deepHours
            snapshot.sleepBedtime = sleep.bedtime
            snapshot.sleepWakeTime = sleep.wakeTime
        }

        snapshot.weightKg = checkIn.weightKg
        snapshot.waterLitres = checkIn.waterLitres

        applySymptoms(checkIn.symptoms, to: snapshot)

        return snapshot
    }

    /// Maps present SymptomEntry values onto the corresponding Bool properties of a HealthSnapshot.
    /// Pure mapping — reads entries, writes snapshot flags, no async or I/O.
    private static func applySymptoms(_ entries: [SymptomEntry], to snapshot: HealthSnapshot) {
        for entry in entries where entry.present {
            switch entry.symptomId {
            case "nausea":               snapshot.nausea = true
            case "vomiting":             snapshot.vomiting = true
            case "diarrhea":             snapshot.diarrhea = true
            case "constipation":         snapshot.constipation = true
            case "abdominal_pain":       snapshot.abdominalPain = true
            case "fatigue":              snapshot.fatigue = true
            case "appetite_decreased":   snapshot.appetiteDecreased = true
            case "headache":             snapshot.headache = true
            case "dizziness":            snapshot.dizziness = true
            case "heartburn":            snapshot.heartburn = true
            case "indigestion":          snapshot.indigestion = true
            case "burping":              snapshot.burping = true
            case "bloating":             snapshot.bloating = true
            case "dry_mouth":            snapshot.drymouth = true
            case "hair_loss":            snapshot.hairLoss = true
            case "muscle_loss":          snapshot.muscleLoss = true
            case "mood_changes":         snapshot.moodChanges = true
            case "insomnia":             snapshot.insomnia = true
            case "palpitations":         snapshot.palpitations = true
            case "hot_flashes":          snapshot.hotFlashes = true
            case "low_blood_sugar":      snapshot.lowBloodSugar = true
            case "pancreatitis":         snapshot.pancreatitis = true
            case "gallbladder":          snapshot.gallbladder = true
            case "kidney_injury":        snapshot.kidneyInjury = true
            case "thyroid_tumor":        snapshot.thyroidTumor = true
            case "allergic_reaction":    snapshot.allergicReaction = true
            case "vision_changes":       snapshot.visionChanges = true
            case "injection_site":       snapshot.injectionSiteReaction = true
            case "dark_urine":           snapshot.darkUrine = true
            case "infrequent_urination": snapshot.infrequentUrination = true
            default: break
            }
        }
    }
}
