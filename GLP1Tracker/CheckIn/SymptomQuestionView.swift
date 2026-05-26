import SwiftUI

struct SymptomQuestionView: View {
    let symptom: Symptom
    @Binding var answer: Bool
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                categoryBadge
                Text("Did you experience")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(symptom.name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("today?")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Button {
                    answer = false
                    onNext()
                } label: {
                    Text("No")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    answer = true
                    onNext()
                } label: {
                    Text("Yes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(symptom.warningLevel == .stopDrug ? Color.red : Color.accentColor)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private var categoryBadge: some View {
        switch symptom.warningLevel {
        case .stopDrug:
            Label("Serious symptom", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.bold())
                .foregroundStyle(.red)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.12), in: Capsule())
        case .caution:
            Label("Monitor", systemImage: "exclamationmark.circle")
                .font(.caption.bold())
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12), in: Capsule())
        case .none:
            EmptyView()
        }
    }
}
