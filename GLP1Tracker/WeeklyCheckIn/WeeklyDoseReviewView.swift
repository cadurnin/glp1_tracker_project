import SwiftUI

struct WeeklyDoseReviewView: View {
    @Binding var doseMg: Double
    let onNext: () -> Void

    private let doses: [(String, Double)] = [
        ("0.25 mg", 0.25),
        ("0.5 mg", 0.5),
        ("1.0 mg", 1.0),
        ("1.7 mg", 1.7),
        ("2.4 mg", 2.4),
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "syringe.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("What dose are you on this week?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(doses, id: \.1) { label, mg in
                    Button {
                        doseMg = mg
                    } label: {
                        HStack {
                            Text(label)
                            Spacer()
                            if doseMg == mg {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding()
                        .background(
                            doseMg == mg
                                ? Color.accentColor.opacity(0.15)
                                : Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal)

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
}
