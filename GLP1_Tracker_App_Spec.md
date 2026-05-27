# GLP-1 Tracker — Claude Code Spec

## Overview

Build a personal iOS app for tracking GLP-1 medication symptoms, health stats, and injection cycles. The app is for personal use only — no backend, no accounts, no App Store. All data is stored locally using SwiftData and synced with Apple HealthKit where applicable.

---

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Local Database:** SwiftData
- **Health Integration:** HealthKit (read and write)
- **Target:** iOS 17+, iPhone only
- **Distribution:** Personal device via Apple Developer account (no App Store)

---

## Architecture — One File Per Purpose

Follow strict single-responsibility file structure:

```
GLP1Tracker/
├── App/
│   └── GLP1TrackerApp.swift          # App entry point
│
├── Models/
│   ├── DailyCheckIn.swift            # SwiftData model for daily check-ins
│   ├── WeeklyCheckIn.swift           # SwiftData model for weekly check-ins
│   ├── SymptomEntry.swift            # SwiftData model for individual symptom logs
│   ├── InjectionLog.swift            # SwiftData model for injection records
│   └── HealthSnapshot.swift          # SwiftData model for mirrored HealthKit data
│
├── HealthKit/
│   ├── HealthKitManager.swift        # Permissions, read/write coordinator
│   ├── HeartRateReader.swift         # Reads resting heart rate from HealthKit
│   ├── SleepReader.swift             # Reads sleep data from HealthKit
│   ├── HealthKitWriter.swift         # Writes water, weight, symptoms to HealthKit
│   └── HealthKitMirror.swift         # Copies HealthKit data into SwiftData for analysis
│
├── CheckIn/
│   ├── CheckInWizardView.swift       # Wizard container — manages page flow
│   ├── WeightEntryView.swift         # Page 1: Weight input with skip
│   ├── WaterEntryView.swift          # Page 2: Water intake with skip
│   ├── SymptomQuestionView.swift     # Reusable yes/no symptom question page
│   ├── SeverityRatingView.swift      # Follow-up severity 1–5 page
│   ├── OverallScoreView.swift        # Overall feel score 1–10
│   ├── InjectionEntryView.swift      # Injection log (shown on injection days)
│   └── CheckInSummaryView.swift      # Summary screen with insights + warnings
│
├── WeeklyCheckIn/
│   ├── WeeklyCheckInView.swift       # Weekly check-in flow container
│   ├── WeeklyWeightView.swift        # Weekly weight entry
│   ├── WeeklyDoseReviewView.swift    # Dose review page
│   ├── WeeklyRatingView.swift        # Overall week rating
│   └── WeeklyNotesView.swift         # Free text notes
│
├── Symptoms/
│   ├── SymptomList.swift             # Master list of all symptoms with metadata
│   └── SymptomWarningEvaluator.swift # Evaluates symptoms for warnings/stop-drug alerts
│
├── Insights/
│   ├── InsightsView.swift            # Insights screen
│   ├── OutlierDetector.swift         # Detects HealthKit data outliers vs personal baseline
│   └── SymptomPatternAnalyzer.swift  # Frequency, severity trends, new symptom detection
│
├── History/
│   ├── HistoryView.swift             # Tab: charts + list toggle
│   ├── ChartDashboardView.swift      # Charts with time range toggle
│   └── CheckInListView.swift         # Scrollable list of past check-ins
│
├── Export/
│   └── CSVExporter.swift             # Exports all data to CSV
│
├── Notifications/
│   └── NotificationManager.swift     # Daily check-in reminder at user-set time
│
└── Settings/
    └── SettingsView.swift            # Notification time, current dose, profile setup
```

---

## Data Models

### DailyCheckIn (SwiftData)
```swift
@Model class DailyCheckIn {
    var date: Date
    var weightKg: Double?              // nil if skipped
    var waterLitres: Double?           // nil if skipped
    var overallScore: Int              // 1–10
    var injectionLogId: UUID?          // links to InjectionLog if injection day
    var cycleDay: Int                  // 1–7, calculated from last injection date
    var symptoms: [SymptomEntry]
    var healthSnapshotId: UUID?        // links to HealthSnapshot
}
```

### SymptomEntry (SwiftData)
```swift
@Model class SymptomEntry {
    var symptomId: String              // matches id in SymptomList
    var present: Bool
    var severity: Int?                 // 1–5 if present, nil if not
    var date: Date
    var checkInId: UUID
}
```

### InjectionLog (SwiftData)
```swift
@Model class InjectionLog {
    var date: Date
    var time: Date
    var doseMg: Double                 // e.g. 0.25, 0.5, 1.0, 2.0
    var doseLabel: String              // e.g. "0.25mg", "0.5mg"
    var injectionSiteNote: String?
}
```

### HealthSnapshot (SwiftData)
```swift
@Model class HealthSnapshot {
    var date: Date
    // Auto-pulled from Watch via HealthKit
    var restingHeartRate: Double?
    var sleepHours: Double?
    var sleepREM: Double?
    var sleepDeep: Double?
    var sleepBedtime: Date?
    var sleepWakeTime: Date?
    // Written to HealthKit then mirrored back
    var weightKg: Double?
    var waterLitres: Double?
    // Symptoms written to HealthKit + mirrored (Bool = present that day)
    var nausea: Bool
    var vomiting: Bool
    var diarrhea: Bool
    var constipation: Bool
    var heartburn: Bool
    var abdominalCramps: Bool
    var bloating: Bool
    var fatigue: Bool
    var headache: Bool
    var dizziness: Bool
    var shortnessOfBreath: Bool
    var moodChanges: Bool
    var hairLoss: Bool
    var appetiteChanges: Bool
    // SwiftData-only symptoms (no HealthKit equivalent)
    var darkUrine: Bool
    var infrequentUrination: Bool
    var brainFog: Bool
    var neckLump: Bool
    var hoarseness: Bool
    var troubleSwallowing: Bool
    var injectionSiteReaction: Bool
    var abdominalPainRadiating: Bool
    var absoluteConstipation: Bool
    var visionChanges: Bool
    var hypoglycemiaSymptoms: Bool
    var rapidHeartRate: Bool
    var upperStomachPain: Bool
    var extremeBloating: Bool
}
```

### WeeklyCheckIn (SwiftData)
```swift
@Model class WeeklyCheckIn {
    var weekStartDate: Date
    var weightKg: Double?
    var doseAtTimeOfCheckIn: Double
    var weekRating: Int                // 1–10
    var notes: String?
    var symptomSummary: String?        // auto-generated summary
}
```

---

## Symptom Master List

Define in `SymptomList.swift` as a static array. Each symptom has:
- `id`: String identifier
- `name`: Display name
- `category`: common / lessCommon / rare / situational
- `trackingSeverity`: Bool (true = yes/no then severity scale; false = yes/no only)
- `warningLevel`: none / caution / stopDrug
- `warningMessage`: String shown when triggered

### Common Symptoms (severity 1–5 if present)
| ID | Name | Warning Level |
|---|---|---|
| nausea | Nausea | none |
| vomiting | Vomiting | caution |
| diarrhea | Diarrhea | none |
| constipation | Constipation | none |
| indigestion | Indigestion / Heartburn | none |
| abdominal_pain_general | Abdominal Pain (general) | none |
| fatigue | Fatigue | none |
| headache | Headache | none |
| appetite_loss | Appetite Loss | none |
| bloating | Bloating | none |

### Less Common Symptoms (yes/no → severity if yes)
| ID | Name | Warning Level | Warning Message |
|---|---|---|---|
| dark_urine | Dark Urine | caution | "Dark urine may indicate dehydration or kidney stress. Monitor closely and increase fluid intake." |
| infrequent_urination | Infrequent Urination | caution | "Reduced urination combined with vomiting or diarrhea may indicate dehydration." |
| dizziness | Dizziness | caution | "Dizziness may indicate dehydration or low blood sugar. Rest and hydrate." |
| acid_reflux | Acid Reflux | none | — |
| brain_fog | Brain Fog | none | — |
| upper_stomach_pain | Severe Upper Stomach Pain | stopDrug | "⚠️ Severe upper stomach pain may indicate acute gallbladder disease. Stop taking your medication and contact your doctor immediately." |
| jaundice | Yellowing of Skin or Eyes (Jaundice) | stopDrug | "⚠️ Jaundice is a serious symptom. Stop taking your medication and seek medical care immediately." |

### Rare / Severe Symptoms (yes/no only — immediate stop-drug warning if yes)
| ID | Name | Warning Message |
|---|---|---|
| abdominal_pain_radiating | Severe Abdominal Pain Radiating to Back | "🚨 This may indicate acute pancreatitis. Stop taking your medication immediately and go to the emergency room." |
| absolute_constipation | Absolute Constipation (cannot pass stool or gas for days) | "🚨 This may indicate a bowel obstruction. Stop taking your medication immediately and seek emergency medical care." |
| extreme_bloating | Extreme Abdominal Bloating or Distension | "🚨 Severe bloating may indicate a serious gastrointestinal complication. Stop taking your medication and seek medical care." |
| neck_lump | New Lump or Swelling in Neck | "🚨 A new neck lump may indicate a thyroid reaction (FDA Boxed Warning). Stop taking your medication and contact your doctor immediately." |
| hoarseness | Persistent Hoarseness | "🚨 Persistent hoarseness combined with neck changes may indicate a thyroid reaction. Contact your doctor." |
| trouble_swallowing | Trouble Swallowing | "🚨 Difficulty swallowing may indicate a thyroid reaction (FDA Boxed Warning). Stop taking your medication and contact your doctor." |
| shortness_of_breath | Shortness of Breath | "🚨 Shortness of breath requires immediate medical evaluation. Stop taking your medication and seek emergency care if severe." |
| rapid_heart_rate | Noticeably Rapid Heart Rate | "⚠️ A significantly elevated heart rate beyond your usual GLP-1 increase (2–4 bpm) should be evaluated by a doctor." |
| mood_changes | Significant Mood Changes | "⚠️ Mood changes have been reported with GLP-1 medications. Discuss with your doctor if persistent." |

### Situational Symptoms (yes/no → severity if yes)
| ID | Name | Warning Level | Warning Message |
|---|---|---|---|
| hypoglycemia_symptoms | Dizziness + Sweating + Confusion (together) | stopDrug | "🚨 These symptoms together may indicate hypoglycemia (low blood sugar). Eat fast-acting sugar immediately and contact your doctor." |
| vision_changes | Any Sudden Vision Changes | stopDrug | "🚨 Sudden vision changes may indicate diabetic retinopathy complications. Contact your doctor immediately." |
| hair_loss | Hair Loss | none | — |
| injection_site_reaction | Injection Site Reaction (redness, swelling) | caution | "Monitor injection site reactions. Rotate injection sites and consult your doctor if reactions worsen." |

---

## Warning Display Rules

In `SymptomWarningEvaluator.swift`:

- **stopDrug warnings:** Full-screen modal with red background, bold text, clear "Contact Doctor" CTA. Cannot be dismissed without confirming they have read it.
- **caution warnings:** Amber banner shown on the summary screen. Dismissible.
- **Combination rule:** If `dark_urine` + `dizziness` + `infrequent_urination` are all present on the same day → escalate to stopDrug warning: "These symptoms together may indicate acute kidney injury from dehydration. Stop taking your medication and seek medical care immediately."

---

## Daily Check-In Wizard Flow

Managed by `CheckInWizardView.swift` as a paged flow. One question per screen. No progress bar. No back navigation within the wizard.

**Page order:**
1. **WeightEntryView** — "What is your weight today?" Number input (kg or lbs, user preference). Skip button.
2. **WaterEntryView** — "How much water have you had today?" Input in litres or oz. Skip button.
3. **SymptomQuestionView** × N — For each symptom in order (common → less common → rare → situational):
   - "Did you experience [symptom name] today?" → Yes / No
   - If Yes → **SeverityRatingView** — "How severe was it?" → 1–5 scale (for severity-tracked symptoms)
4. **OverallScoreView** — "How do you feel overall today?" → 1–10 slider
5. **InjectionEntryView** — "Was today an injection day?" → Yes → log dose, time. No → skip.
6. **CheckInSummaryView** — Shows everything logged. Pulls HealthKit data silently in background. Displays insights and any warnings.

---

## Check-In Summary Screen

`CheckInSummaryView.swift` shows:

- All symptoms logged today (present ones highlighted)
- Weight and water entered
- Resting heart rate (auto-pulled from HealthKit)
- Sleep from last night (auto-pulled from HealthKit)
- Current cycle day (e.g. "Day 3 of your injection cycle")
- **Insights section** — any patterns or outliers detected today
- **Warnings section** — caution or stop-drug alerts for any symptoms logged

After viewing summary, user taps "Done" to save all data.

---

## HealthKit Integration

### Permissions Required
Request on first launch via `HealthKitManager.swift`:

**Read:**
- HKQuantityTypeIdentifier.restingHeartRate
- HKCategoryTypeIdentifier.sleepAnalysis
- HKQuantityTypeIdentifier.bodyMass
- HKQuantityTypeIdentifier.dietaryWater
- HKQuantityTypeIdentifier.bloodPressureSystolic
- HKQuantityTypeIdentifier.bloodPressureDiastolic
- HKQuantityTypeIdentifier.bloodGlucose
- HKCategoryTypeIdentifier.nausea
- HKCategoryTypeIdentifier.appetiteChanges
- HKCategoryTypeIdentifier.vomiting

**Write:**
- HKQuantityTypeIdentifier.bodyMass
- HKQuantityTypeIdentifier.dietaryWater
- HKCategoryTypeIdentifier.nausea
- HKCategoryTypeIdentifier.appetiteChanges
- HKCategoryTypeIdentifier.vomiting
- HKCategoryTypeIdentifier.heartburn
- HKCategoryTypeIdentifier.diarrhea
- HKCategoryTypeIdentifier.constipation
- HKCategoryTypeIdentifier.abdominalCramps
- HKCategoryTypeIdentifier.bloating
- HKCategoryTypeIdentifier.fatigue
- HKCategoryTypeIdentifier.headache
- HKCategoryTypeIdentifier.dizziness
- HKCategoryTypeIdentifier.shortnessOfBreath
- HKCategoryTypeIdentifier.moodChanges
- HKCategoryTypeIdentifier.hairLoss

### Heart Rate Logic (`HeartRateReader.swift`)
- Query HKQuantityTypeIdentifier.restingHeartRate for today
- Return the most recent resting heart rate value for the day
- Fall back to average of all heart rate samples for the day if resting HR unavailable
- Mirror value into `HealthSnapshot` in SwiftData with timestamp

### Sleep Logic (`SleepReader.swift`)
- Query HKCategoryTypeIdentifier.sleepAnalysis for last night's sleep (previous 24 hours)
- Calculate: total sleep time, REM duration, Deep sleep duration, bedtime, wake time
- Mirror into `HealthSnapshot` in SwiftData

### Writing to HealthKit (`HealthKitWriter.swift`)

Every supported symptom is written to HealthKit on check-in save, AND mirrored into SwiftData via `HealthKitMirror.swift` for local analysis.

**Quantity types (numeric values):**
- Write weight as HKQuantityTypeIdentifier.bodyMass
- Write water intake as HKQuantityTypeIdentifier.dietaryWater

**Category types (present = HKCategoryValuePresent, not present = HKCategoryValueNotPresent):**
- Nausea → HKCategoryTypeIdentifier.nausea
- Appetite loss → HKCategoryTypeIdentifier.appetiteChanges
- Vomiting → HKCategoryTypeIdentifier.vomiting
- Heartburn/Indigestion → HKCategoryTypeIdentifier.heartburn
- Diarrhea → HKCategoryTypeIdentifier.diarrhea
- Constipation → HKCategoryTypeIdentifier.constipation
- Abdominal pain → HKCategoryTypeIdentifier.abdominalCramps
- Bloating → HKCategoryTypeIdentifier.bloating
- Fatigue → HKCategoryTypeIdentifier.fatigue
- Headache → HKCategoryTypeIdentifier.headache
- Dizziness → HKCategoryTypeIdentifier.dizziness
- Shortness of breath → HKCategoryTypeIdentifier.shortnessOfBreath
- Mood changes → HKCategoryTypeIdentifier.moodChanges
- Hair loss → HKCategoryTypeIdentifier.hairLoss

**Symptoms with NO HealthKit equivalent — SwiftData only:**
- Dark urine
- Infrequent urination
- Brain fog
- Neck lump
- Hoarseness
- Trouble swallowing
- Injection site reaction
- Abdominal pain radiating to back
- Absolute constipation (distinct from regular constipation)
- Vision changes
- Hypoglycemia symptom cluster
- Rapid heart rate (tracked separately from Watch HR data)
- Upper stomach pain / jaundice
- Extreme bloating (distinct from regular bloating)

**Mirror rule:** After every HealthKit write, immediately read the written value back and store it in `HealthSnapshot` in SwiftData so the app has its own complete local record for analysis.

---

## Injection Cycle Logic

In `InjectionLog.swift` and used throughout:

- Store each injection with date and time
- `cycleDay` is calculated as: `daysSinceLastInjection + 1` (injection day = Day 1)
- Every check-in, symptom entry, and health snapshot is tagged with `cycleDay`
- This enables cycle-relative analysis in insights

---

## Weekly Check-In Flow

Separate from daily check-in. Triggered by a weekly notification or accessible from home screen.

**Pages:**
1. Weight entry
2. Current dose review — "Are you still on [current dose]?" Yes / No → if No, log new dose
3. Overall week rating — 1–10
4. Free text notes — open text field
5. Summary — auto-generated week summary showing average symptoms, weight change, best and worst day

---

## Insights Screen

`InsightsView.swift` — dedicated screen, not notifications.

### Outlier Detection (`OutlierDetector.swift`)
- After 7+ days of data, calculate personal baseline (mean + standard deviation) for:
  - Resting heart rate
  - Total sleep hours
  - Water intake
  - Weight change velocity (rate of change per week)
- Flag any value more than 1.5 standard deviations from personal mean
- Display as: "Your resting heart rate today (89 bpm) is higher than your usual range (68–74 bpm)"
- Show trend arrow (improving / worsening / stable) for each metric

### Symptom Pattern Analysis (`SymptomPatternAnalyzer.swift`)
- **Frequency alerts:** "You have experienced nausea 5 out of the last 7 days"
- **Severity escalation:** "Your headache severity has increased over the past 2 weeks (avg 1.2 → avg 3.1)"
- **New symptom detection:** Flag any symptom appearing for the first time or returning after 14+ days of absence
- **Cycle correlation:** "Your nausea is most frequent on Day 2 of your injection cycle"
- **Dose correlation:** After a dose increase, flag if symptom frequency/severity increases in the following 7 days

### Summary screen insights (shown after each check-in)
- Surface any of the above that are relevant to today's data
- Always show warnings first before general insights

---

## History Screen

`HistoryView.swift` — accessible from main tab bar.

### Charts (`ChartDashboardView.swift`)
Using Swift Charts framework. Time range toggle: 1 Week / 1 Month / 3 Months / All Time.

Charts to include:
- Weight over time (line chart)
- Resting heart rate over time (line chart) with cycle day overlay
- Sleep hours over time (bar chart)
- Symptom frequency heatmap (which symptoms appeared most, by week)
- Nausea severity over time (line chart)
- Water intake over time (bar chart)
- Overall feel score over time (line chart)

### List (`CheckInListView.swift`)
- Scrollable list of all daily check-ins, newest first
- Each row shows: date, cycle day, overall score, top symptoms present
- Tap to expand full check-in detail

---

## CSV Export

`CSVExporter.swift` — accessible from Settings screen.

Export one CSV file with all data combined. Columns:

```
Date, CycleDay, Weight(kg), Water(L), OverallScore, RestingHR, SleepHours, 
SleepREM, SleepDeep, DoseMg, InjectionDay,
Nausea_Present, Nausea_Severity, Vomiting_Present, Vomiting_Severity,
Diarrhea_Present, Constipation_Present, Constipation_Severity,
Indigestion_Present, AbdominalPain_Present, AbdominalPain_Severity,
Fatigue_Present, Fatigue_Severity, Headache_Present, Headache_Severity,
AppetiteLoss_Present, Bloating_Present, DarkUrine_Present,
InfrequentUrination_Present, Dizziness_Present, AcidReflux_Present,
BrainFog_Present, UpperStomachPain_Present, Jaundice_Present,
AbdominalPainRadiating_Present, AbsoluteConstipation_Present,
ExtremeBloating_Present, NeckLump_Present, Hoarseness_Present,
TroubleSwallowing_Present, ShortnessOfBreath_Present, RapidHeartRate_Present,
MoodChanges_Present, HypoglycemiaSymptoms_Present, VisionChanges_Present,
HairLoss_Present, InjectionSiteReaction_Present,
Notes
```

Use `UIActivityViewController` to share the CSV file so user can AirDrop, email, or save to Files.

---

## Notifications

`NotificationManager.swift`:
- Request notification permission on first launch
- Schedule a daily local notification at user-set time (default: 8:00 PM)
- Notification text: "Time for your daily check-in 📋"
- Tapping notification opens directly to the check-in wizard
- Weekly check-in reminder: every Sunday at the daily check-in time

---

## Settings Screen

`SettingsView.swift`:
- Daily reminder time picker
- Unit preference: kg vs lbs, litres vs oz
- Current GLP-1 medication name (free text)
- Current dose (picker: 0.25mg / 0.5mg / 1.0mg / 1.7mg / 2.0mg or custom)
- Injection day of week
- Export CSV button
- HealthKit permissions status + re-request button

---

## Navigation Structure

Main tab bar with 4 tabs:
1. **Check In** — today's check-in wizard (or summary if already completed today)
2. **History** — charts + list view
3. **Insights** — insights and pattern analysis screen
4. **Settings** — settings + export

---

## Important Implementation Notes

1. **No network requests** — everything is local. No analytics, no telemetry, no API calls.
2. **HealthKit pull happens silently** at the end of each check-in, not during the wizard flow.
3. **Cycle day** must be recalculated on every app open based on the last injection log entry.
4. **Stop-drug warnings** must be shown as full-screen modals that require user acknowledgment before proceeding to the Done button.
5. **Baseline for outlier detection** should not be calculated until 7+ days of data exist — before that, show "Building your baseline..." on the insights screen.
6. **All dates stored in UTC**, displayed in local timezone.
7. **SwiftData container** should be configured with CloudKit disabled — local only.
8. **No iCloud sync** — data stays on device only.

---

## Medical Disclaimer (shown on first launch)

Display a one-time disclaimer on first launch:

> "This app is a personal tracking tool only. It is not a medical device and does not provide medical advice. All warnings shown are informational prompts to consult your healthcare provider — they are not a diagnosis. Always follow the guidance of your prescribing physician."

User must tap "I Understand" to proceed.
