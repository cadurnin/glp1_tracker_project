import SwiftUI

/// Full-screen red modal shown when a logged symptom triggers a "stop drug" warning.
/// Requires the user to confirm they understand before dismissing.
struct StopDrugWarningModal: View {
    let warning: WarningResult
    let onDismiss: () -> Void

    @State private var confirmed = false

    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                Text("Important Warning")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text(warning.message)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Toggle(isOn: $confirmed) {
                    Text("I understand and will contact my doctor")
                        .foregroundStyle(.white)
                        .font(.subheadline.weight(.medium))
                }
                .tint(.white)
                .padding(.horizontal)

                Button {
                    if confirmed { onDismiss() }
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(confirmed ? Color.red : Color.gray)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .controlSize(.large)
                .disabled(!confirmed)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
    }
}
