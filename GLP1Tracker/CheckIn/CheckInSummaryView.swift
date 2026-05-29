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

