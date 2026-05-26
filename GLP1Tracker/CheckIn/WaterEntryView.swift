import SwiftUI

struct WaterEntryView: View {
    @Binding var water: Double?
    @AppStorage("useLitres") private var useLitres = true
    let onNext: () -> Void

    @State private var rawValue: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 8) {
                Text("How much water have you had today?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(useLitres ? "litres" : "oz")
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
                        water = useLitres ? val : val * 0.0295735
                    }
                    onNext()
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(rawValue.isEmpty)

                Button("Skip") { water = nil; onNext() }
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onAppear { focused = true }
    }
}
