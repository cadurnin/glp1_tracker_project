import SwiftUI

/// A large tappable card used for Yes/No questions throughout the check-in wizard.
struct QuestionnaireButton: View {
    enum Style { case muted, accent }

    let label: String
    let icon: String
    let isSelected: Bool
    let selectedColor: Color
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? selectedColor.opacity(0.15) : Color(.systemFill))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.title3.bold())
                        .foregroundStyle(isSelected ? selectedColor : Color(.tertiaryLabel))
                }

                Text(label)
                    .font(.headline)
                    .foregroundStyle(isSelected ? selectedColor : Color(.secondaryLabel))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                isSelected
                    ? selectedColor.opacity(0.08)
                    : Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isSelected ? selectedColor.opacity(0.35) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}
