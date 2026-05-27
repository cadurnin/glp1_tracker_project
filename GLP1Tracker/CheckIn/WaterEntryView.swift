import SwiftUI

struct WaterEntryView: View {
    var state: CheckInState
    @AppStorage("useLitres") private var useLitres = true
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                // Icon + question
                VStack(spacing: 14) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.cyan)

                    Text("How much water today?")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Optional — tap to enter")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Large number display
                VStack(spacing: 6) {
                    ZStack {
                        TextField("", text: Binding(
                            get: { state.waterInput },
                            set: { state.waterInput = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .focused($focused)
                        .opacity(0)
                        .frame(width: 1, height: 1)

                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text(state.waterInput.isEmpty ? "–––" : state.waterInput)
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(state.waterInput.isEmpty ? Color(.tertiaryLabel) : Color.primary)
                                .contentTransition(.numericText())

                            Text(useLitres ? "L" : "oz")
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
                            .strokeBorder(focused ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                    .animation(.easeInOut(duration: 0.2), value: focused)
                    .onTapGesture { focused = true }

                    if !state.waterInput.isEmpty {
                        Button("Clear") {
                            state.waterInput = ""
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }
                }

                // Hydration targets hint
                HStack(spacing: 16) {
                    ForEach(useLitres ? [1.5, 2.0, 2.5] : [50.0, 64.0, 85.0], id: \.self) { amount in
                        Button {
                            state.waterInput = amount.truncatingRemainder(dividingBy: 1) == 0
                                ? String(Int(amount))
                                : String(format: "%.1f", amount)
                            focused = false
                        } label: {
                            Text(amount.truncatingRemainder(dividingBy: 1) == 0
                                 ? "\(Int(amount))\(useLitres ? "L" : "oz")"
                                 : String(format: "%.1f\(useLitres ? "L" : "oz")", amount))
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: 0) {
                Divider()
                VStack(spacing: 10) {
                    Button {
                        focused = false
                        state.step = .symptoms
                    } label: {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Skip") {
                        state.waterInput = ""
                        focused = false
                        state.step = .symptoms
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
