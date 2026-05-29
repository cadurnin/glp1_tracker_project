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

