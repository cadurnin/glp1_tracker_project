import SwiftUI

struct SeverityRatingView: View {
    let symptomName: String
    @Binding var severity: Int
    let onNext: () -> Void

    private let labels = ["Mild", "Moderate", "Noticeable", "Severe", "Very Severe"]
    private let colors: [Color] = [.green, .yellow, .orange, .orange, .red]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("How severe was your")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(symptomName)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                Text("\(severity)")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(colors[severity - 1])

                Text(labels[severity - 1])
                    .font(.headline)
                    .foregroundStyle(colors[severity - 1])

                Slider(value: Binding(
                    get: { Double(severity) },
                    set: { severity = Int($0) }
                ), in: 1...5, step: 1)
                .tint(colors[severity - 1])
                .padding(.horizontal)

                HStack {
                    Text("1 — Mild")
                    Spacer()
                    Text("5 — Very Severe")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            }

            Button {
                onNext()
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onAppear { severity = max(1, severity) }
    }
}
