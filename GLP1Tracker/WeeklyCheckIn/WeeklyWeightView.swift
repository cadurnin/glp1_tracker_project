import SwiftUI

struct WeeklyWeightView: View {
    @Binding var weightInput: String
    let onNext: () -> Void
    @AppStorage("useKg") private var useKg = true

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "scalemass.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("Weekly weigh-in")
                .font(.title2.bold())

            HStack {
                TextField("Optional", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)

                Text(useKg ? "kg" : "lbs")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

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
