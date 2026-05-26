import SwiftUI

struct OverallScoreView: View {
    @Binding var score: Int
    let onNext: () -> Void

    private let emojis = ["😫", "😩", "😟", "😕", "😐", "🙂", "😊", "😄", "😁", "🤩"]
    private func color(for score: Int) -> Color {
        switch score {
        case 1...3: return .red
        case 4...6: return .orange
        case 7...8: return .yellow
        default: return .green
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How do you feel overall today?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Text(emojis[score - 1])
                    .font(.system(size: 72))
                Text("\(score) / 10")
                    .font(.title.bold())
                    .foregroundStyle(color(for: score))
            }

            Slider(value: Binding(
                get: { Double(score) },
                set: { score = Int($0) }
            ), in: 1...10, step: 1)
            .tint(color(for: score))
            .padding(.horizontal)

            HStack {
                Text("1 — Terrible")
                Spacer()
                Text("10 — Great")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)

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
    }
}
