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

/// Holds mutable state for the multi-step check-in wizard.
/// Tracks the current step, date, injection details, measurements, symptoms, and severity ratings.
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

    /// Filters symptoms that were marked present and track severity.
    var answeredSymptoms: [Symptom] {
        SymptomList.all.filter { symptomAnswers[$0.id] == true && $0.tracksSeverity }
    }
}

// MARK: - Wizard View

/// Multi-step check-in wizard that guides users through daily symptom, injection, and measurement entry.
/// Shows a summary if the user has already checked in today; otherwise displays the wizard flow.
struct CheckInWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query(sort: \InjectionLog.date, order: .reverse) private var injections: [InjectionLog]

    @State private var state = CheckInState()
    @AppStorage("useKg") private var useKg = true
    @AppStorage("useLitres") private var useLitres = true

    /// Returns true if the most recent check-in is from today.
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

    /// Returns the SwiftUI view matching the current wizard step.
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

    /// Persists the wizard state to the model context and HealthKit, then resets the wizard.
    /// Triggers async HealthKit write and snapshot building without blocking the UI.
    private func save() {
        let checkIn = DailyCheckIn(
            date: state.date,
            overallScore: state.overallScore
        )

        checkIn.weightKg = CheckInTransformer.weightKg(from: state.weightInput, useKg: useKg)
        checkIn.waterLitres = CheckInTransformer.waterLitres(from: state.waterInput, useLitres: useLitres)
        checkIn.cycleDay = InjectionLog.cycleDay(from: injections.first?.date)

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
            checkIn.cycleDay = 1
        }

        let entries = CheckInTransformer.buildSymptomEntries(
            answers: state.symptomAnswers,
            severities: state.symptomSeverities,
            date: state.date,
            checkInId: checkIn.id
        )
        checkIn.symptoms.append(contentsOf: entries)

        modelContext.insert(checkIn)

        // HealthKit write — capture date now; state is reset below before the Task body runs
        let checkInDate = checkIn.date
        Task {
            await HealthKitWriter.write(checkIn: checkIn)
            let snapshot = await HealthKitMirror.buildSnapshot(for: checkInDate, checkIn: checkIn)
            modelContext.insert(snapshot)
        }

        // Reset wizard
        state = CheckInState()
    }

}

// MARK: - Today Summary View

/// Displays a summary of today's check-in after the user has already completed one.
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
