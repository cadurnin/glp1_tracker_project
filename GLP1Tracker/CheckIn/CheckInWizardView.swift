import SwiftUI
import SwiftData
import Observation

// MARK: Wizard step enum

enum WizardStep: Equatable, Hashable {
    case weight
    case water
    case symptomQuestion(Int)
    case symptomSeverity(Int)
    case overallScore
    case injection
    case summary
}

// MARK: Shared check-in state

@Observable
final class CheckInState {
    var weight: Double? = nil
    var water: Double? = nil
    var symptomAnswers: [String: Bool] = [:]
    var symptomSeverities: [String: Int] = [:]
    var overallScore: Int = 5
    var isInjectionDay: Bool = false
    var injectionDose: Double = 0.25
    var injectionTime: Date = Date()
    var injectionSiteNote: String = ""

    func symptomEntries(checkInId: UUID, date: Date) -> [SymptomEntry] {
        SymptomList.all.compactMap { symptom in
            guard let present = symptomAnswers[symptom.id] else { return nil }
            return SymptomEntry(
                symptomId: symptom.id,
                present: present,
                severity: present ? symptomSeverities[symptom.id] : nil,
                date: date,
                checkInId: checkInId
            )
        }
    }
}

// MARK: Wizard container

struct CheckInWizardView: View {
    @Query(sort: \InjectionLog.date, order: .reverse) private var injectionLogs: [InjectionLog]
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]

    @State private var state = CheckInState()
    @State private var step: WizardStep = .weight
    @State private var completed = false

    private var alreadyCheckedInToday: Bool {
        guard let last = checkIns.first else { return false }
        return Calendar.current.isDateInToday(last.date)
    }

    private var cycleDay: Int {
        InjectionLog.cycleDay(from: injectionLogs.first?.date)
    }

    var body: some View {
        NavigationStack {
            Group {
                if (completed || alreadyCheckedInToday), let recent = checkIns.first {
                    TodaySummaryView(checkIn: recent)
                } else {
                    wizardPage
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .id(step)
                        .animation(.easeInOut(duration: 0.25), value: step)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var wizardPage: some View {
        switch step {
        case .weight:
            WeightEntryView(weight: $state.weight) { advance() }

        case .water:
            WaterEntryView(water: $state.water) { advance() }

        case .symptomQuestion(let idx):
            SymptomQuestionView(
                symptom: SymptomList.all[idx],
                answer: Binding(
                    get: { state.symptomAnswers[SymptomList.all[idx].id] ?? false },
                    set: { state.symptomAnswers[SymptomList.all[idx].id] = $0 }
                )
            ) { advance() }

        case .symptomSeverity(let idx):
            let id = SymptomList.all[idx].id
            SeverityRatingView(
                symptomName: SymptomList.all[idx].name,
                severity: Binding(
                    get: { state.symptomSeverities[id] ?? 1 },
                    set: { state.symptomSeverities[id] = $0 }
                )
            ) { advance() }

        case .overallScore:
            OverallScoreView(score: $state.overallScore) { advance() }

        case .injection:
            InjectionEntryView(
                isInjectionDay: $state.isInjectionDay,
                dose: $state.injectionDose,
                time: $state.injectionTime,
                siteNote: $state.injectionSiteNote
            ) { advance() }

        case .summary:
            CheckInSummaryView(state: state, cycleDay: cycleDay) {
                completed = true
            }
        }
    }

    private var navigationTitle: String {
        switch step {
        case .weight: return "Weight"
        case .water: return "Water Intake"
        case .symptomQuestion(let i): return "Symptom \(i + 1) of \(SymptomList.all.count)"
        case .symptomSeverity: return "Severity"
        case .overallScore: return "Overall Feeling"
        case .injection: return "Injection"
        case .summary: return "Summary"
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.25)) {
            step = nextStep(after: step)
        }
    }

    private func nextStep(after current: WizardStep) -> WizardStep {
        switch current {
        case .weight:
            return .water
        case .water:
            return .symptomQuestion(0)
        case .symptomQuestion(let idx):
            let symptom = SymptomList.all[idx]
            if state.symptomAnswers[symptom.id] == true && symptom.tracksSeverity {
                return .symptomSeverity(idx)
            }
            return nextSymptomOrScore(after: idx)
        case .symptomSeverity(let idx):
            return nextSymptomOrScore(after: idx)
        case .overallScore:
            return .injection
        case .injection:
            return .summary
        case .summary:
            return .summary
        }
    }

    private func nextSymptomOrScore(after idx: Int) -> WizardStep {
        let next = idx + 1
        return next < SymptomList.all.count ? .symptomQuestion(next) : .overallScore
    }
}

// MARK: Today's completed check-in view

struct TodaySummaryView: View {
    let checkIn: DailyCheckIn
    @AppStorage("useKg") private var useKg = true
    @AppStorage("useLitres") private var useLitres = true

    private var presentSymptoms: [SymptomEntry] {
        checkIn.symptoms.filter { $0.present }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title)
                    Text("Check-in complete!")
                        .font(.title2.bold())
                }
                .padding(.top)

                Text("Day \(checkIn.cycleDay) of your injection cycle")
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    infoCard("Overall", "\(checkIn.overallScore)/10", "heart.fill", .pink)
                    if let w = checkIn.weightKg {
                        let display = useKg ? w : w / 0.453592
                        infoCard("Weight", String(format: "%.1f \(useKg ? "kg" : "lbs")", display), "scalemass", .blue)
                    }
                    if let w = checkIn.waterLitres {
                        let display = useLitres ? w : w / 0.0295735
                        infoCard("Water", String(format: "%.1f \(useLitres ? "L" : "oz")", display), "drop.fill", .cyan)
                    }
                }

                if !presentSymptoms.isEmpty {
                    Text("Symptoms logged")
                        .font(.headline)
                    ForEach(presentSymptoms) { entry in
                        if let symptom = SymptomList.symptom(for: entry.symptomId) {
                            HStack {
                                Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                                Text(symptom.name)
                                Spacer()
                                if let s = entry.severity { Text("Severity \(s)/5").foregroundStyle(.secondary).font(.caption) }
                            }
                        }
                    }
                } else {
                    Text("No symptoms reported")
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            .padding(.horizontal)
        }
    }

    private func infoCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.caption.bold()).foregroundStyle(color)
            Text(value).font(.title3.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
