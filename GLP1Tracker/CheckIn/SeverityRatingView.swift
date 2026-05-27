import SwiftUI

struct SeverityRatingView: View {
    var state: CheckInState

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(state.answeredSymptoms) { symptom in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(symptom.name)
                                .font(.subheadline.weight(.medium))
                            HStack {
                                Text("Severity: \(state.symptomSeverities[symptom.id] ?? 1)/5")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Slider(value: Binding(
                                    get: { Double(state.symptomSeverities[symptom.id] ?? 1) },
                                    set: { state.symptomSeverities[symptom.id] = Int($0) }
                                ), in: 1...5, step: 1)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Rate each symptom's severity")
                }
            }

            Button {
                state.step = .overallScore
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .navigationTitle("Severity")
    }
}
