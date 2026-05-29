import SwiftUI

/// Expandable list row showing summary and optional details for a single DailyCheckIn.
struct CheckInRow: View {
    let checkIn: DailyCheckIn
    let isExpanded: Bool
    let useKg: Bool
    let useLitres: Bool

    private var presentSymptoms: [SymptomEntry] {
        checkIn.symptoms.filter { $0.present }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if isExpanded {
                Divider()
                expandedDetails
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(checkIn.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                Text("Overall: \(checkIn.overallScore)/10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !presentSymptoms.isEmpty {
                Text("\(presentSymptoms.count) symptom\(presentSymptoms.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                if let w = checkIn.weightKg {
                    let display = useKg ? w : UnitConverter.lbsFrom(kg: w)
                    miniStat(label: useKg ? "kg" : "lbs", value: String(format: "%.1f", display))
                }
                if let w = checkIn.waterLitres {
                    let display = useLitres ? w : UnitConverter.ozFrom(litres: w)
                    miniStat(label: useLitres ? "L water" : "oz water", value: String(format: "%.1f", display))
                }
                if checkIn.cycleDay > 0 {
                    miniStat(label: "cycle day", value: "\(checkIn.cycleDay)")
                }
            }

            if !presentSymptoms.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(presentSymptoms) { entry in
                        if let symptom = SymptomList.all.first(where: { $0.id == entry.symptomId }) {
                            SymptomChip(symptom: symptom, severity: entry.severity)
                        }
                    }
                }
            }
        }
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
