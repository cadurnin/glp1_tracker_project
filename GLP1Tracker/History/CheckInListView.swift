import SwiftUI
import SwiftData

struct CheckInListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]

    @AppStorage("useKg") private var useKg = true
    @AppStorage("useLitres") private var useLitres = true

    @State private var expandedId: UUID?
    @State private var checkInToEdit: DailyCheckIn?
    @State private var checkInToDelete: DailyCheckIn?
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            ForEach(checkIns) { checkIn in
                CheckInRow(
                    checkIn: checkIn,
                    isExpanded: expandedId == checkIn.id,
                    useKg: useKg,
                    useLitres: useLitres
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedId = expandedId == checkIn.id ? nil : checkIn.id
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        checkInToDelete = checkIn
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        checkInToEdit = checkIn
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .contextMenu {
                    Button {
                        checkInToEdit = checkIn
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        checkInToDelete = checkIn
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $checkInToEdit) { checkIn in
            EditCheckInView(checkIn: checkIn)
        }
        .alert("Delete Check-In?", isPresented: $showDeleteConfirm, presenting: checkInToDelete) { item in
            Button("Delete", role: .destructive) {
                delete(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("This will permanently delete the check-in for \(item.date.formatted(date: .abbreviated, time: .omitted)).")
        }
    }

    private func delete(_ checkIn: DailyCheckIn) {
        modelContext.delete(checkIn)
    }
}

// MARK: - Row

private struct CheckInRow: View {
    let checkIn: DailyCheckIn
    let isExpanded: Bool
    let useKg: Bool
    let useLitres: Bool

    private var presentSymptoms: [SymptomEntry] {
        checkIn.symptoms.filter { $0.present }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
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

            // Expanded details
            if isExpanded {
                Divider()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    if let w = checkIn.weightKg {
                        let display = useKg ? w : w / 0.453592
                        miniStat(label: useKg ? "kg" : "lbs", value: String(format: "%.1f", display))
                    }
                    if let w = checkIn.waterLitres {
                        let display = useLitres ? w : w / 0.0295735
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
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
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
