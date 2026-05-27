import SwiftUI

struct OverallScoreView: View {
    var state: CheckInState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "face.smiling.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)

            Text("How do you feel overall today?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Text("\(state.overallScore) / 10")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)

                Slider(value: Binding(
                    get: { Double(state.overallScore) },
                    set: { state.overallScore = Int($0) }
                ), in: 1...10, step: 1)
                .tint(scoreColor)

                HStack {
                    Text("Poor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Great")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                state.step = .summary
            } label: {
                Text("Review Summary")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
        }
        .padding()
    }

    private var scoreColor: Color {
        switch state.overallScore {
        case 1...3: return .red
        case 4...6: return .orange
        default: return .green
        }
    }
}
