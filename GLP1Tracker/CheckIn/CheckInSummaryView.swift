import SwiftUI
import SwiftData

struct CheckInSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InjectionLog.date, order: .reverse) private var injectionLogs: [InjectionLog]

    let state: CheckInState
    let cycleDay: Int
    let onDone: () -> Void

    @State private var heartRate: Double? = nil
    @State private var sleepData: SleepData? = nil
    @State private var isLoadingHK = true
    @State private var pendingStopWarnings: [WarningResult] = []
    @State private var cautionWarnings: [WarningResult] = []
    @State private var currentStopWarning: WarningResult? = nil
    @State private var acknowledgedAllStopWarnings = false
    @State private var isSaving = false
    @AppStorage("useKg") private var useKg = true
    @AppStorage("useLitres") private var useLitres = true

    private var presentSymptoms: [Symptom] {
        SymptomList.all.filter { state.symptomAnswers[$0.id] == true }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Today's Summary")
                    .font(.largeTitle.bold())
                    .padding(.top)

                cycleDaySection
                statsSection
                healthKitSection
                symptomsSection

                if !cautionWarnings.isEmpty {
                    cautionBannersSection
                }

                Spacer(minLength: 20)

                Button {
                    save()
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!acknowledgedAllStopWarnings || isSaving)
                .padding(.bottom)
            }
            .padding(.horizontal)
        }
        .task {
            await loadHealthKitData()
            evaluateWarnings()
        }
        .fullScreenCover(item: $currentStopWarning) { warning in
            StopDrugWarningModal(warning: warning) {
                dismissStopWarning()
            }
        }
    }

    // MARK: Sections

    private var cycleDaySection: some View {
        HStack {
            Image(systemName: "syringe")
                .foregroundStyle(Color.accentColor)
            Text("Day \(cycleDay) of your injection cycle")
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats").font(.headline).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Overall", value: "\(state.overallScore)/10", icon: "heart.fill", color: .pink)
                if let w = state.weight {
                    let display = useKg ? w : w / 0.453592
                    let unit = useKg ? "kg" : "lbs"
                    StatCard(title: "Weight", value: String(format: "%.1f \(unit)", display), icon: "scalemass", color: .blue)
                }
                if let w = state.water {
                    let display = useLitres ? w : w / 0.0295735
                    let unit = useLitres ? "L" : "oz"
                    StatCard(title: "Water", value: String(format: "%.1f \(unit)", display), icon: "drop.fill", color: .cyan)
                }
                if state.isInjectionDay {
                    StatCard(title: "Injection", value: String(format: "%.2fmg", state.injectionDose), icon: "syringe.fill", color: .purple)
                }
            }
        }
    }

    private var healthKitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Data").font(.headline).foregroundStyle(.secondary)
            if isLoadingHK {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if let hr = heartRate {
                        StatCard(title: "Resting HR", value: "\(Int(hr)) bpm", icon: "waveform.path.ecg", color: .red)
                    }
                    if let sleep = sleepData {
                        StatCard(title: "Sleep", value: String(format: "%.1f hrs", sleep.totalHours), icon: "bed.double.fill", color: .indigo)
                        if sleep.remHours > 0 {
                            StatCard(title: "REM", value: String(format: "%.0f min", sleep.remHours * 60), icon: "moon.fill", color: .purple)
                        }
                        if sleep.deepHours > 0 {
                            StatCard(title: "Deep", value: String(format: "%.0f min", sleep.deepHours * 60), icon: "zzz", color: .blue)
                        }
                    }
                    if heartRate == nil && sleepData == nil {
                        Text("No HealthKit data available for today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptoms").font(.headline).foregroundStyle(.secondary)
            if presentSymptoms.isEmpty {
                Text("No symptoms reported today")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(presentSymptoms) { symptom in
                        SymptomChip(symptom: symptom, severity: state.symptomSeverities[symptom.id])
                    }
                }
            }
        }
    }

    private var cautionBannersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cautions").font(.headline).foregroundStyle(.secondary)
            ForEach(cautionWarnings) { warning in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text(warning.message)
                        .font(.subheadline)
                }
                .padding()
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: Actions

    private func loadHealthKitData() async {
        heartRate = await HeartRateReader().readTodayRestingHeartRate()
        sleepData = await SleepReader().readLastNightSleep()
        isLoadingHK = false
    }

    private func evaluateWarnings() {
        let draftEntries = state.symptomEntries(checkInId: UUID(), date: Date())
        let allWarnings = SymptomWarningEvaluator.evaluate(entries: draftEntries)
        pendingStopWarnings = allWarnings.filter { $0.level == .stopDrug }
        cautionWarnings = allWarnings.filter { $0.level == .caution }

        if pendingStopWarnings.isEmpty {
            acknowledgedAllStopWarnings = true
        } else {
            currentStopWarning = pendingStopWarnings.first
        }
    }

    private func dismissStopWarning() {
        if !pendingStopWarnings.isEmpty {
            pendingStopWarnings.removeFirst()
        }
        currentStopWarning = nil

        if pendingStopWarnings.isEmpty {
            acknowledgedAllStopWarnings = true
        } else {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                currentStopWarning = pendingStopWarnings.first
            }
        }
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        let date = Date()
        let checkInId = UUID()
        let symptoms = state.symptomEntries(checkInId: checkInId, date: date)

        let checkIn = DailyCheckIn(
            date: date,
            weightKg: state.weight,
            waterLitres: state.water,
            overallScore: state.overallScore,
            cycleDay: cycleDay
        )
        checkIn.id = checkInId
        symptoms.forEach { checkIn.symptoms.append($0) }
        modelContext.insert(checkIn)

        if state.isInjectionDay {
            let log = InjectionLog(
                date: date,
                time: state.injectionTime,
                doseMg: state.injectionDose,
                doseLabel: String(format: "%.2fmg", state.injectionDose),
                injectionSiteNote: state.injectionSiteNote.isEmpty ? nil : state.injectionSiteNote
            )
            modelContext.insert(log)
            checkIn.injectionLogId = log.id
        }

        Task {
            let writer = HealthKitWriter()
            if let weight = state.weight { try? await writer.writeWeight(weight, date: date) }
            if let water = state.water { try? await writer.writeWater(water, date: date) }
            await writer.writeSymptoms(symptoms, date: date)

            let snapshot = await HealthKitMirror().buildSnapshot(for: date, checkIn: checkIn)
            modelContext.insert(snapshot)
            checkIn.healthSnapshotId = snapshot.id

            isSaving = false
            onDone()
        }
    }
}

// MARK: Supporting views

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SymptomChip: View {
    let symptom: Symptom
    let severity: Int?

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(chipColor)
                .frame(width: 8, height: 8)
            Text(symptom.name)
                .font(.caption.bold())
            if let s = severity {
                Text("(\(s)/5)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(chipColor.opacity(0.12), in: Capsule())
    }

    private var chipColor: Color {
        switch symptom.warningLevel {
        case .stopDrug: return .red
        case .caution: return .orange
        case .none: return Color.accentColor
        }
    }
}

struct StopDrugWarningModal: View {
    let warning: WarningResult
    let onAcknowledge: () -> Void

    @State private var confirmed = false

    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)

                Text("Important Warning")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text(warning.message)
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Toggle(isOn: $confirmed) {
                    Text("I have read and understood this warning")
                        .foregroundStyle(.white)
                        .font(.subheadline)
                }
                .tint(.white)
                .padding(.horizontal)

                Button {
                    onAcknowledge()
                } label: {
                    Text("I Understand")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .controlSize(.large)
                .disabled(!confirmed)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: FlowLayout helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let rowHeights: [CGFloat] = rows.map { row in
            row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        }
        let totalSpacing = spacing * CGFloat(max(0, rows.count - 1))
        let height = rowHeights.reduce(0, +) + totalSpacing
        return CGSize(width: proposal.width ?? 0, height: max(0, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.endIndex - 1].isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.endIndex - 1].append(subview)
            x += size.width + spacing
        }
        return rows
    }
}
