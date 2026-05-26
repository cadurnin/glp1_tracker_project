import SwiftUI

struct WeeklyDoseReviewView: View {
    @Binding var dose: Double
    @AppStorage("currentDoseMg") private var storedDose: Double = 0.25
    let onNext: () -> Void

    @State private var doseChanged = false
    private let doseOptions: [Double] = [0.25, 0.5, 1.0, 1.7, 2.0]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Are you still on the same dose?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Current dose: \(storedDose, specifier: "%.2f") mg")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                Button {
                    dose = storedDose
                    onNext()
                } label: {
                    Text("Yes, same dose").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    doseChanged = true
                } label: {
                    Text("No, changed").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal)

            if doseChanged {
                VStack(spacing: 16) {
                    Text("Select your new dose").font(.headline)
                    Picker("New dose", selection: $dose) {
                        ForEach(doseOptions, id: \.self) { d in
                            Text("\(d, specifier: "%.2f") mg").tag(d)
                        }
                    }
                    .pickerStyle(.wheel)

                    Button {
                        storedDose = dose
                        onNext()
                    } label: {
                        Text("Confirm new dose").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            Spacer()
        }
        .padding()
        .animation(.easeInOut, value: doseChanged)
        .onAppear { dose = storedDose }
    }
}
