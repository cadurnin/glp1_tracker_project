import SwiftUI
import SwiftData

struct CheckInListView: View {
    let checkIns: [DailyCheckIn]

    @State private var expandedId: UUID? = nil

    var body: some View {
        if checkIns.isEmpty {
            ContentUnavailableView(
                "No check-ins yet",
                systemImage: "calendar.badge.plus",
                description: Text("Complete your first daily check-in to see it here.")
            )
        } else {
            LazyVStack(spacing: 0) {
                ForEach(checkIns.sorted { $0.date > $1.date }) { checkIn in
                    CheckInRow(checkIn: checkIn, isExpanded: expandedId == checkIn.id) {
                        withAnimation(.easeInOut) {
                            expandedId = expandedId == checkIn.id ? nil : checkIn.id
                        }
                    }
                    Divider()
                }
            }
        }
    }
}

private struct CheckInRow: View {
    let checkIn: DailyCheckIn
    let isExpanded: Bool
    let onTap: () -> Void

    private var presentSymptoms: [SymptomEntry] {
        checkIn.symptoms.filter(\.present)
    }

    private var topSymptomNames: String {
        presentSymptoms.prefix(3)
            .compactMap { SymptomList.symptom(for: $0.symptomId)?.name }
            .joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(checkIn.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                            .font(.subheadline.bold())
                        Text("Day \(checkIn.cycleDay)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        scoreView
                        if !presentSymptoms.isEmpty {
                            Text("\(presentSymptoms.count) symptoms")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var scoreView: some View {
        ZStack {
            Circle()
                .fill(scoreColor.opacity(0.15))
                .frame(width: 36, height: 36)
            Text("\(checkIn.overallScore)")
                .font(.subheadline.bold())
                .foregroundStyle(scoreColor)
        }
    }

    private var scoreColor: Color {
        switch checkIn.overallScore {
        case 1...3: return .red
        case 4...6: return .orange
        case 7...8: return .yellow
        default: return .green
        }
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack(spacing: 16) {
                if let w = checkIn.weightKg {
                    Label(String(format: "%.1f kg", w), systemImage: "scalemass")
                }
                if let wt = checkIn.waterLitres {
                    Label(String(format: "%.1f L", wt), systemImage: "drop.fill")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !presentSymptoms.isEmpty {
                Text("Symptoms").font(.caption.bold()).foregroundStyle(.secondary)
                FlowLayout(spacing: 6) {
                    ForEach(presentSymptoms) { entry in
                        if let symptom = SymptomList.symptom(for: entry.symptomId) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                                Text(symptom.name)
                                if let s = entry.severity {
                                    Text("(\(s))").foregroundStyle(.secondary)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1), in: Capsule())
                        }
                    }
                }
            } else {
                Text("No symptoms reported").font(.caption).foregroundStyle(.secondary).italic()
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}
