import SwiftUI
import SwiftData

private enum WeeklyStep {
    case weight, doseReview, rating, notes, summary
}

struct WeeklyCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @AppStorage("currentDoseMg") private var currentDose: Double = 0.25

    @State private var step: WeeklyStep = .weight
    @State private var weight: Double? = nil
    @State private var dose: Double = 0.25
    @State private var rating: Int = 5
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .weight:
                    WeeklyWeightView(weight: $weight) { step = .doseReview }
                case .doseReview:
                    WeeklyDoseReviewView(dose: $dose) { step = .rating }
                case .rating:
                    WeeklyRatingView(rating: $rating) { step = .notes }
                case .notes:
                    WeeklyNotesView(notes: $notes) { step = .summary }
                case .summary:
                    WeeklySummaryView(
                        weight: weight,
                        dose: dose,
                        rating: rating,
                        notes: notes,
                        recentCheckIns: Array(checkIns.prefix(7))
                    ) { save() }
                }
            }
            .navigationTitle("Weekly Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            .animation(.easeInOut(duration: 0.25), value: step)
        }
    }

    private func save() {
        let recentCheckIns = Array(checkIns.prefix(7))
        let avgSymptoms = buildSymptomSummary(from: recentCheckIns)
        let weekStart = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()

        let entry = WeeklyCheckIn(
            weekStartDate: weekStart,
            weightKg: weight,
            doseAtTimeOfCheckIn: dose,
            weekRating: rating,
            notes: notes.isEmpty ? nil : notes,
            symptomSummary: avgSymptoms
        )
        modelContext.insert(entry)
        dismiss()
    }

    private func buildSymptomSummary(from checkIns: [DailyCheckIn]) -> String {
        guard !checkIns.isEmpty else { return "" }
        var counts: [String: Int] = [:]
        for c in checkIns {
            for s in c.symptoms where s.present {
                counts[s.symptomId, default: 0] += 1
            }
        }
        let top = counts.sorted { $0.value > $1.value }.prefix(3)
        let names = top.compactMap { SymptomList.symptom(for: $0.key)?.name }
        let avgScore = checkIns.map(\.overallScore).reduce(0, +) / checkIns.count
        return "Avg score: \(avgScore)/10. Top symptoms: \(names.joined(separator: ", "))"
    }
}

// MARK: Weekly summary screen

private struct WeeklySummaryView: View {
    let weight: Double?
    let dose: Double
    let rating: Int
    let notes: String
    let recentCheckIns: [DailyCheckIn]
    let onSave: () -> Void

    @AppStorage("useKg") private var useKg = true

    private var avgScore: Double {
        guard !recentCheckIns.isEmpty else { return 0 }
        return Double(recentCheckIns.map(\.overallScore).reduce(0, +)) / Double(recentCheckIns.count)
    }

    private var bestDay: DailyCheckIn? {
        recentCheckIns.max(by: { $0.overallScore < $1.overallScore })
    }

    private var worstDay: DailyCheckIn? {
        recentCheckIns.min(by: { $0.overallScore < $1.overallScore })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Week Summary").font(.largeTitle.bold()).padding(.top)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    summaryCard("Week rating", "\(rating)/10", "star.fill", .yellow)
                    summaryCard("Avg daily score", String(format: "%.1f/10", avgScore), "chart.line.uptrend.xyaxis", .green)
                    summaryCard("Dose", String(format: "%.2f mg", dose), "syringe.fill", .purple)
                    if let w = weight {
                        let display = useKg ? w : w / 0.453592
                        summaryCard("Weight", String(format: "%.1f \(useKg ? "kg" : "lbs")", display), "scalemass", .blue)
                    }
                }

                if let best = bestDay {
                    HStack {
                        Image(systemName: "sun.max.fill").foregroundStyle(.yellow)
                        Text("Best day: \(best.date.formatted(.dateTime.weekday(.wide)))")
                            .font(.subheadline)
                        Spacer()
                        Text("\(best.overallScore)/10").font(.subheadline.bold())
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }

                if let worst = worstDay {
                    HStack {
                        Image(systemName: "cloud.fill").foregroundStyle(.gray)
                        Text("Toughest day: \(worst.date.formatted(.dateTime.weekday(.wide)))")
                            .font(.subheadline)
                        Spacer()
                        Text("\(worst.overallScore)/10").font(.subheadline.bold())
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }

                if !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes").font(.headline)
                        Text(notes).foregroundStyle(.secondary)
                    }
                }

                Button {
                    onSave()
                } label: {
                    Text("Save Weekly Check-In").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom)
            }
            .padding(.horizontal)
        }
    }

    private func summaryCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.caption.bold()).foregroundStyle(color)
            Text(value).font(.title3.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
