import SwiftUI

struct WeightEntryView: View {
    var state: CheckInState
    @AppStorage("useKg") private var useKg = true
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                // Icon + question
                VStack(spacing: 14) {
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.accentColor)

                    Text("What's your weight today?")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Optional — tap to enter")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Large number display
                VStack(spacing: 6) {
                    ZStack {
                        // Invisible text field captures input
                        TextField("", text: Binding(
                            get: { state.weightInput },
                            set: { state.weightInput = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .focused($focused)
                        .opacity(0)
                        .frame(width: 1, height: 1)

                        // Visible display
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text(state.weightInput.isEmpty ? "–––" : state.weightInput)
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(state.weightInput.isEmpty ? Color(.tertiaryLabel) : Color.primary)
                                .contentTransition(.numericText())

                            Text(useKg ? "kg" : "lbs")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .onTapGesture { focused = true }
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(focused ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                    .animation(.easeInOut(duration: 0.2), value: focused)
                    .onTapGesture { focused = true }

                    if !state.weightInput.isEmpty {
                        Button("Clear") {
                            state.weightInput = ""
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            // Buttons
            VStack(spacing: 0) {
                Divider()
                VStack(spacing: 10) {
                    Button {
                        focused = false
                        state.step = .water
                    } label: {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Skip") {
                        state.weightInput = ""
                        focused = false
                        state.step = .water
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
        .onAppear { focused = true }
    }
}
