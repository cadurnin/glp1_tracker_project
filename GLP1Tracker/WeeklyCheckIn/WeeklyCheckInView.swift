import SwiftUI
import SwiftData

private enum WeeklyStep {
    case weight, dose, rating, notes, summary
}

struct WeeklyCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("useKg") private var useKg = true

    @State private var step: WeeklyStep = .weight
    @State private var weightInput: String = ""
    @State private var doseMg: Double = 0.5
    @State private var rating: Int = 7
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .weight:
                    WeeklyWeightView(weightInput: $weightInput) { step = .dose }
                case .dose:
                    WeeklyDoseReviewView(doseMg: $doseMg) { step = .rating }
                case .rating:
                    WeeklyRatingView(rating: $rating) { step = .notes }
                case .notes:
                    WeeklyNotesView(notes: $notes) { step = .summary }
                case .summary:
                    WeeklySummaryView(
                        weightInput: weightInput,
                        doseMg: doseMg,
                        rating: rating,
                        notes: notes,
                        useKg: useKg
                    ) {
                        save()
                    }
                }
            }
            .navigationTitle("Weekly Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let weekStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) ?? Date()

        var weightKg: Double?
        if let val = Double(weightInput), val > 0 {
            weightKg = useKg ? val : UnitConverter.kgFrom(lbs: val)
        }

        let checkIn = WeeklyCheckIn(
            weekStartDate: weekStart,
            weightKg: weightKg,
            doseAtTimeOfCheckIn: doseMg,
            weekRating: rating,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(checkIn)
        dismiss()
    }
}

// MARK: - Summary

private struct WeeklySummaryView: View {
    let weightInput: String
    let doseMg: Double
    let rating: Int
    let notes: String
    let useKg: Bool
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(icon: "star.fill", color: .yellow, label: "Week Rating", value: "\(rating)/10")
                    StatCard(icon: "syringe.fill", color: .green, label: "Dose", value: String(format: "%.2f mg", doseMg))
                    if !weightInput.isEmpty, let w = Double(weightInput) {
                        StatCard(icon: "scalemass.fill", color: .blue, label: useKg ? "kg" : "lbs", value: String(format: "%.1f", w))
                    }
                }
                .padding(.horizontal)

                if !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                onSave()
            } label: {
                Text("Save")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}
