import SwiftUI

// MARK: - Stat Card

/// A small grid card showing an icon, a value, and a label.
struct StatCard: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Symptom Chip

/// A pill-shaped tag showing a symptom name and optional severity rating.
struct SymptomChip: View {
    let symptom: Symptom
    let severity: Int?

    var body: some View {
        HStack(spacing: 4) {
            Text(symptom.name)
            if let sev = severity {
                Text("(\(sev)/5)")
                    .opacity(0.7)
            }
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(chipColor.opacity(0.15), in: Capsule())
        .foregroundStyle(chipColor)
    }

    private var chipColor: Color {
        switch symptom.warningLevel {
        case .stopDrug: return .red
        case .consultDoctor: return .orange
        case .normal: return Color.accentColor
        }
    }
}
