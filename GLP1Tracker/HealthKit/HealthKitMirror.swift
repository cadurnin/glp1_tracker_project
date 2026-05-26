import HealthKit
import Foundation

struct HealthKitMirror {
    private let store: HKHealthStore

    init(store: HKHealthStore = HealthKitManager.shared.store) {
        self.store = store
    }

    func buildSnapshot(for date: Date, checkIn: DailyCheckIn) async -> HealthSnapshot {
        let snapshot = HealthSnapshot(date: date)

        snapshot.weightKg = checkIn.weightKg
        snapshot.waterLitres = checkIn.waterLitres

        let entries = checkIn.symptoms
        func isPresent(_ id: String) -> Bool {
            entries.first(where: { $0.symptomId == id })?.present ?? false
        }

        snapshot.nausea = isPresent("nausea")
        snapshot.vomiting = isPresent("vomiting")
        snapshot.diarrhea = isPresent("diarrhea")
        snapshot.constipation = isPresent("constipation")
        snapshot.heartburn = isPresent("indigestion")
        snapshot.abdominalCramps = isPresent("abdominal_pain_general")
        snapshot.bloating = isPresent("bloating")
        snapshot.fatigue = isPresent("fatigue")
        snapshot.headache = isPresent("headache")
        snapshot.dizziness = isPresent("dizziness")
        snapshot.shortnessOfBreath = isPresent("shortness_of_breath")
        snapshot.moodChanges = isPresent("mood_changes")
        snapshot.hairLoss = isPresent("hair_loss")
        snapshot.appetiteChanges = isPresent("appetite_loss")
        snapshot.darkUrine = isPresent("dark_urine")
        snapshot.infrequentUrination = isPresent("infrequent_urination")
        snapshot.brainFog = isPresent("brain_fog")
        snapshot.neckLump = isPresent("neck_lump")
        snapshot.hoarseness = isPresent("hoarseness")
        snapshot.troubleSwallowing = isPresent("trouble_swallowing")
        snapshot.injectionSiteReaction = isPresent("injection_site_reaction")
        snapshot.abdominalPainRadiating = isPresent("abdominal_pain_radiating")
        snapshot.absoluteConstipation = isPresent("absolute_constipation")
        snapshot.visionChanges = isPresent("vision_changes")
        snapshot.hypoglycemiaSymptoms = isPresent("hypoglycemia_symptoms")
        snapshot.rapidHeartRate = isPresent("rapid_heart_rate")
        snapshot.upperStomachPain = isPresent("upper_stomach_pain")
        snapshot.extremeBloating = isPresent("extreme_bloating")

        snapshot.restingHeartRate = await HeartRateReader(store: store).readTodayRestingHeartRate()

        if let sleep = await SleepReader(store: store).readLastNightSleep() {
            snapshot.sleepHours = sleep.totalHours
            snapshot.sleepREM = sleep.remHours
            snapshot.sleepDeep = sleep.deepHours
            snapshot.sleepBedtime = sleep.bedtime
            snapshot.sleepWakeTime = sleep.wakeTime
        }

        return snapshot
    }
}
