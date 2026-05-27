import SwiftUI

struct CheckInSummaryView: View {
    var state: CheckInState
    let onSave: () -> Void

    @AppStorage("useKg") private var useKg = true
    @AppStorage("useLitres") private var useLitres = true

    @State private var pendingStopWarnings: [WarningResult] = []
    @State private var currentStopWarning: WarningResult?

    private var warnings: [WarningResult] {
        let entries = SymptomList.all.map { symptom in
            SymptomEntry(
                symptomId: symptom.id,
                present: state.symptomAnswers[symptom.id] ?? false,
                severity: state.symptomSeverities[symptom.id],
                date: state.date,
                checkInId: UUID()
            )
        }
        return SymptomWarningEvaluator.evaluate(entries: entries)
    }

    private var stopWarnings: [WarningResult] {
        warnings.filter { $0.level == .stopDrug }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if !state.weightInput.isEmpty, let w = Double(state.weightInput) {
                        StatCard(
                            icon: "scalemass.fill",
                            color: .blue,
                            label: useKg ? "Weight (kg)" : "Weight (lbs)",
                            value: String(format: "%.1f", w)
                        )
                    }
                    if !state.waterInput.isEmpty, let w = Double(state.waterInput) {
                        StatCard(
                            icon: "drop.fill",
                            color: .cyan,
                            label: useLitres ? "Water (L)" : "Water (oz)",
                            value: String(format: "%.1f", w)
                        )
                    }
                    StatCard(
                        icon: "face.smiling.fill",
                        color: .yellow,
                        label: "Overall",
                        value: "\(state.overallScore)/10"
                    )
                    if state.isInjectionDay {
                        StatCard(
                            icon: "syringe.fill",
                            color: .green,
                            label: "Dose",
                            value: state.doseLabel
                        )
                    }
                }
                .padding(.horizontal)

                // Warnings
                if !warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Warnings")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(warnings) { warning in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: warning.level == .stopDrug ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                    .foregroundStyle(warning.level == .stopDrug ? Color.red : Color.orange)
                                Text(warning.message)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(
                                (warning.level == .stopDrug ? Color.red : Color.orange).opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .padding(.horizontal)
                        }
                    }
                }

                // Symptoms
                let presentSymptoms = SymptomList.all.filter { state.symptomAnswers[$0.id] == true }
                if !presentSymptoms.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Symptoms Today")
                            .font(.headline)
                            .padding(.horizontal)

                        FlowLayout(spacing: 8) {
                            ForEach(presentSymptoms) { symptom in
                                SymptomChip(symptom: symptom,
                                            severity: state.symptomSeverities[symptom.id])
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                let stops = stopWarnings
                if stops.isEmpty {
                    onSave()
                } else {
                    pendingStopWarnings = stops
                    currentStopWarning = stops.first
                }
            } label: {
                Text("Save Check-In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(item: $currentStopWarning) { warning in
            StopDrugWarningModal(warning: warning) {
                dismissStopWarning()
            }
        }
    }

    private func dismissStopWarning() {
        pendingStopWarnings.removeFirst()
        currentStopWarning = nil
        if let next = pendingStopWarnings.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentStopWarning = next
            }
        } else {
            onSave()
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Symptom Chip

struct SymptomChip: View {
    let symptom: Symptom
    let severity: Int?

    var body: some View {
        HStack(spacing: 4) {
            Text(symptom.name)
            if let sev = severity {
                Text("(\(sev)/5)")
                    .opacity(0.7)
            }
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(chipColor.opacity(0.15), in: Capsule())
        .foregroundStyle(chipColor)
    }

    private var chipColor: Color {
        switch symptom.warningLevel {
        case .stopDrug: return .red
        case .consultDoctor: return .orange
        case .normal: return Color.accentColor
        }
    }
}

// MARK: - Stop Drug Warning Modal

struct StopDrugWarningModal: View {
    let warning: WarningResult
    let onDismiss: () -> Void

    @State private var confirmed = false

    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                Text("Important Warning")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text(warning.message)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Toggle(isOn: $confirmed) {
                    Text("I understand and will contact my doctor")
                        .foregroundStyle(.white)
                        .font(.subheadline.weight(.medium))
                }
                .tint(.white)
                .padding(.horizontal)

                Button {
                    if confirmed { onDismiss() }
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(confirmed ? Color.red : Color.gray)
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

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
