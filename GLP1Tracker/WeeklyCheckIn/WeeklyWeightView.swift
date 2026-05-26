import SwiftUI

struct WeeklyWeightView: View {
    @Binding var weight: Double?
    @AppStorage("useKg") private var useKg = true
    let onNext: () -> Void

    @State private var rawValue: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 8) {
                Text("What is your weight this week?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(useKg ? "kg" : "lbs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            TextField("0.0", text: $rawValue)
                .keyboardType(.decimalPad)
                .font(.system(size: 48, weight: .light))
                .multilineTextAlignment(.center)
                .focused($focused)
                .frame(maxWidth: 200)
            VStack(spacing: 12) {
                Button {
                    if let val = Double(rawValue), val > 0 {
                        weight = useKg ? val : val * 0.453592
                    }
                    onNext()
                } label: {
                    Text("Next").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(rawValue.isEmpty)
                Button("Skip") { weight = nil; onNext() }
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding()
        .onAppear { focused = true }
    }
}
