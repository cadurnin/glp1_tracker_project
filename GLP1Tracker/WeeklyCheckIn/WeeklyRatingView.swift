import SwiftUI

struct WeeklyRatingView: View {
    @Binding var rating: Int
    let onNext: () -> Void

    private let emojis = ["😫", "😩", "😟", "😕", "😐", "🙂", "😊", "😄", "😁", "🤩"]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("How was your week overall?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Text(emojis[rating - 1])
                    .font(.system(size: 72))
                Text("\(rating) / 10")
                    .font(.title.bold())
            }

            Slider(value: Binding(
                get: { Double(rating) },
                set: { rating = Int($0) }
            ), in: 1...10, step: 1)
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
                Text("Next").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}
