import SwiftUI
import SwiftData

// MARK: - Wizard Step

enum WizardStep: Equatable, Hashable {
    case injection
    case weight
    case water
    case symptoms
    case severity
    case overallScore
    case summary
}

// MARK: - Check-In State

@Observable
final class CheckInState {
    var step: WizardStep = .injection
    var date: Date = Date()

    // Injection
    var isInjectionDay: Bool = false
    var doseMg: Double = 0.5
    var doseLabel: String = "0.5 mg"
    var injectionSiteNote: String = ""

    // Stats
    var weightInput: String = ""
    var waterInput: String = ""

    // Symptoms
    var symptomAnswers: [String: Bool] = [:]
    var symptomSeverities: [String: Int] = [:]

    // Overall
    var overallScore: Int = 5

    var answeredSymptoms: [Symptom] {
        SymptomList.all.filter { symptomAnswers[$0.id] == true && $0.tracksSeverity }
    }
}

// MARK: - Wizard View

struct CheckInWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query(sort: \InjectionLog.date, order: .reverse) private var injections: [InjectionLog]

    @State private var state = CheckInState()
    @AppStorage("useKg") private var useKg = true
    @AppStorage("useLitres") private var useLitres = true

    private var hasCheckedInToday: Bool {
        guard let recent = checkIns.first else { return false }
        return Calendar.current.isDateInToday(recent.date)
    }

    var body: some View {
        NavigationStack {
            Group {
                if hasCheckedInToday {
                    if let recent = checkIns.first {
                        TodaySummaryView(checkIn: recent)
                    }
                } else {
                    wizardContent
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private var wizardContent: some View {
        switch state.step {
        case .injection:
            InjectionEntryView(state: state, lastInjection: injections.first)
        case .weight:
            WeightEntryView(state: state)
        case .water:
            WaterEntryView(state: state)
        case .symptoms:
            SymptomQuestionView(state: state)
        case .severity, .overallScore:
            OverallScoreView(state: state)
        case .summary:
            CheckInSummaryView(state: state) {
                save()
            }
        }
    }

    private func save() {
        let checkIn = DailyCheckIn(
            date: state.date,
            overallScore: state.overallScore
        )

        // Weight
        if let val = Double(state.weightInput), val > 0 {
            checkIn.weightKg = useKg ? val : val * 0.453592
        }

        // Water
        if let val = Double(state.waterInput), val > 0 {
            checkIn.waterLitres = useLitres ? val : val * 0.0295735
        }

        // Cycle day
        checkIn.cycleDay = InjectionLog.cycleDay(from: injections.first?.date)

        // Injection log
        if state.isInjectionDay {
            let log = InjectionLog(
                date: state.date,
                time: state.date,
                doseMg: state.doseMg,
                doseLabel: state.doseLabel,
                injectionSiteNote: state.injectionSiteNote.isEmpty ? nil : state.injectionSiteNote
            )
            modelContext.insert(log)
            checkIn.injectionLogId = log.id
        }

        // Symptoms
        for symptom in SymptomList.all {
            let present = state.symptomAnswers[symptom.id] ?? false
            let entry = SymptomEntry(
                symptomId: symptom.id,
                present: present,
                severity: present && symptom.tracksSeverity ? (state.symptomSeverities[symptom.id] ?? 1) : nil,
                date: state.date,
                checkInId: checkIn.id
            )
            checkIn.symptoms.append(entry)
        }

        modelContext.insert(checkIn)

        // HealthKit write
        Task {
            await HealthKitWriter.write(checkIn: checkIn)
            let snapshot = await HealthKitMirror.buildSnapshot(for: state.date, checkIn: checkIn)
            await MainActor.run { modelContext.insert(snapshot) }
        }

        // Reset wizard
        state = CheckInState()
    }
}

// MARK: - Today Summary View

struct TodaySummaryView: View {
    let checkIn: DailyCheckIn

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            Text("You've already checked in today!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Overall score: \(checkIn.overallScore)/10")
                .foregroundStyle(.secondary)
            let present = checkIn.symptoms.filter { $0.present }
            if !present.isEmpty {
                Text("\(present.count) symptom(s) logged")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }
}
