import SwiftUI

struct WeeklyRatingView: View {
    @Binding var rating: Int
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)

            Text("How was your week overall?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Text("\(rating) / 10")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(ratingColor)

                Slider(value: Binding(
                    get: { Double(rating) },
                    set: { rating = Int($0) }
                ), in: 1...10, step: 1)
                .tint(ratingColor)

                HStack {
                    Text("Rough week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Amazing week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                onNext()
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
        }
        .padding()
    }

    private var ratingColor: Color {
        switch rating {
        case 1...3: return .red
        case 4...6: return .orange
        default: return .green
        }
    }
}
