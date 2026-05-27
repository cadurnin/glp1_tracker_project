import SwiftUI

struct SymptomQuestionView: View {
    var state: CheckInState

    @State private var currentIndex = 0
    @State private var showSeverity = false
    @State private var goingForward = true

    private var symptoms: [Symptom] { SymptomList.all }
    private var current: Symptom { symptoms[currentIndex] }
    private var progress: Double { Double(currentIndex + 1) / Double(symptoms.count) }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemFill))
                        .frame(height: 4)
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
            .frame(height: 4)

            Spacer()

            // Card content — keyed so SwiftUI re-renders with transition on each step
            VStack(spacing: 32) {
                // Category + count
                HStack {
                    Text(categoryLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(categoryColor, in: Capsule())

                    Spacer()

                    Text("\(currentIndex + 1) of \(symptoms.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Question
                VStack(spacing: 12) {
                    Text("Did you experience")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text(current.name)
                        .font(.system(size: 30, weight: .bold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if current.warningLevel == .stopDrug {
                        Label("Speak to your doctor if severe", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if current.warningLevel == .consultDoctor {
                        Label("Mention this at your next appointment", systemImage: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity)

                // Severity or Yes/No
                if showSeverity {
                    severityView
                } else {
                    yesNoView
                }
            }
            .padding(.horizontal, 28)
            .id("\(currentIndex)-\(showSeverity)")
            .transition(
                goingForward
                    ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                  removal: .move(edge: .leading).combined(with: .opacity))
                    : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                  removal: .move(edge: .trailing).combined(with: .opacity))
            )

            Spacer()

            // Skip row
            Button("Skip all remaining") {
                state.step = .overallScore
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 24)
        }
        .navigationTitle("Symptoms")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Yes / No

    private var yesNoView: some View {
        HStack(spacing: 16) {
            QuestionnaireButton(
                label: "No",
                icon: "xmark",
                isSelected: state.symptomAnswers[current.id] == false,
                selectedColor: .secondary,
                style: .muted
            ) {
                answer(yes: false)
            }

            QuestionnaireButton(
                label: "Yes",
                icon: "checkmark",
                isSelected: state.symptomAnswers[current.id] == true,
                selectedColor: yesColor,
                style: .accent
            ) {
                answer(yes: true)
            }
        }
    }

    // MARK: Severity

    private var severityView: some View {
        VStack(spacing: 20) {
            Text("How bad is it?")
                .font(.title3.weight(.semibold))

            let currentSev = state.symptomSeverities[current.id] ?? 1

            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        state.symptomSeverities[current.id] = level
                    } label: {
                        VStack(spacing: 6) {
                            Text(severityEmoji(level))
                                .font(.title2)
                            Text("\(level)")
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            currentSev == level
                                ? yesColor.opacity(0.15)
                                : Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(currentSev == level ? yesColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                        .foregroundStyle(currentSev == level ? yesColor : .secondary)
                        .animation(.spring(duration: 0.2), value: currentSev)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Text("Mild")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Severe")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                advance()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(yesColor)
            .controlSize(.large)
        }
    }

    // MARK: Logic

    private func answer(yes: Bool) {
        state.symptomAnswers[current.id] = yes
        if yes && current.tracksSeverity {
            if state.symptomSeverities[current.id] == nil {
                state.symptomSeverities[current.id] = 1
            }
            withAnimation(.easeInOut(duration: 0.25)) {
                goingForward = true
                showSeverity = true
            }
        } else {
            advance()
        }
    }

    private func advance() {
        goingForward = true
        showSeverity = false
        if currentIndex < symptoms.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        } else {
            state.step = .overallScore
        }
    }

    // MARK: Helpers

    private var categoryLabel: String {
        switch current.category {
        case .common:      return "Common"
        case .lessCommon:  return "Less Common"
        case .rare:        return "Rare / Severe"
        case .situational: return "Situational"
        }
    }

    private var categoryColor: Color {
        switch current.category {
        case .common:      return .accentColor
        case .lessCommon:  return .orange
        case .rare:        return .red
        case .situational: return .purple
        }
    }

    private var yesColor: Color {
        switch current.warningLevel {
        case .stopDrug:      return .red
        case .consultDoctor: return .orange
        case .normal:        return Color.accentColor
        }
    }

    private func severityEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "😌"
        case 2: return "😕"
        case 3: return "😣"
        case 4: return "😖"
        default: return "😫"
        }
    }
}
