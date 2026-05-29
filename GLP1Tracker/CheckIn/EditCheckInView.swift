import SwiftUI
import SwiftData

struct EditCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let checkIn: DailyCheckIn

    @AppStorage("useKg") private var useKg = true
    @AppStorage("useLitres") private var useLitres = true

    // Editable fields
    @State private var weightInput: String = ""
    @State private var waterInput: String = ""
    @State private var overallScore: Int = 5
    @State private var symptomAnswers: [String: Bool] = [:]
    @State private var symptomSeverities: [String: Int] = [:]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Stats
                Section("Stats") {
                    HStack {
                        Text(useKg ? "Weight (kg)" : "Weight (lbs)")
                        Spacer()
                        TextField("Optional", text: $weightInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text(useLitres ? "Water (L)" : "Water (oz)")
                        Spacer()
                        TextField("Optional", text: $waterInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overall Feel: \(overallScore)/10")
                            .font(.subheadline)
                        Slider(value: Binding(
                            get: { Double(overallScore) },
                            set: { overallScore = Int($0) }
                        ), in: 1...10, step: 1)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Overall Score")
                }

                // MARK: Symptoms by category
                symptomSection("Common Symptoms", category: .common)
                symptomSection("Less Common", category: .lessCommon)
                symptomSection("Rare / Severe", category: .rare)
                symptomSection("Situational", category: .situational)
            }
            .navigationTitle("Edit Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { populateFields() }
        }
    }

    // MARK: Symptom section builder

    /// Renders a collapsible section of symptoms grouped by category, with toggles and optional severity sliders.
    /// - Parameters:
    ///   - title: The display title for this symptom group.
    ///   - category: The SymptomCategory to filter and display.
    @ViewBuilder
    private func symptomSection(_ title: String, category: SymptomCategory) -> some View {
        let symptoms = SymptomList.all.filter { $0.category == category }
        Section(title) {
            ForEach(symptoms) { symptom in
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(symptom.name, isOn: Binding(
                        get: { symptomAnswers[symptom.id] ?? false },
                        set: { symptomAnswers[symptom.id] = $0 }
                    ))
                    .tint(symptom.warningLevel == .stopDrug ? Color.red : Color.accentColor)

                    if symptomAnswers[symptom.id] == true && symptom.tracksSeverity {
                        HStack {
                            Text("Severity: \(symptomSeverities[symptom.id] ?? 1)/5")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: Binding(
                                get: { Double(symptomSeverities[symptom.id] ?? 1) },
                                set: { symptomSeverities[symptom.id] = Int($0) }
                            ), in: 1...5, step: 1)
                        }
                        .padding(.leading, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: symptomAnswers[symptom.id])
            }
        }
    }

    // MARK: Populate from existing check-in

    /// Loads the check-in data into editor state variables, applying unit conversion if configured.
    /// Initializes all symptoms (present or absent) to allow editing of their status.
    private func populateFields() {
        overallScore = checkIn.overallScore

        if let w = checkIn.weightKg {
            let display = useKg ? w : UnitConverter.lbsFrom(kg: w)
            weightInput = String(format: "%.1f", display)
        }
        if let w = checkIn.waterLitres {
            let display = useLitres ? w : UnitConverter.ozFrom(litres: w)
            waterInput = String(format: "%.1f", display)
        }

        for entry in checkIn.symptoms {
            symptomAnswers[entry.symptomId] = entry.present
            if let sev = entry.severity {
                symptomSeverities[entry.symptomId] = sev
            }
        }

        // Fill in any missing symptom answers as false
        for symptom in SymptomList.all where symptomAnswers[symptom.id] == nil {
            symptomAnswers[symptom.id] = false
        }
    }

    // MARK: Save

    /// Updates the check-in with edited values, rebuilds symptoms, and dismisses the view.
    /// Converts weight and water from user input and display units; replaces all symptom entries.
    private func save() {
        checkIn.weightKg = Self.weightKg(from: weightInput, useKg: useKg)
        checkIn.waterLitres = Self.waterLitres(from: waterInput, useLitres: useLitres)
        checkIn.overallScore = overallScore

        // Update symptoms — delete existing, insert updated
        for entry in checkIn.symptoms { modelContext.delete(entry) }
        checkIn.symptoms.removeAll()
        checkIn.symptoms.append(contentsOf: Self.buildSymptomEntries(
            answers: symptomAnswers,
            severities: symptomSeverities,
            date: checkIn.date,
            checkInId: checkIn.id
        ))

        dismiss()
    }

    /// Returns the weight in kg from a user-entered string.
    /// Returns nil when the input is empty; preserves nil to clear an optional field.
    private static func weightKg(from input: String, useKg: Bool) -> Double? {
        guard !input.isEmpty else { return nil }
        guard let val = Double(input), val > 0 else { return nil }
        return useKg ? val : UnitConverter.kgFrom(lbs: val)
    }

    /// Returns the water amount in litres from a user-entered string.
    /// Returns nil when the input is empty; preserves nil to clear an optional field.
    private static func waterLitres(from input: String, useLitres: Bool) -> Double? {
        guard !input.isEmpty else { return nil }
        guard let val = Double(input), val > 0 else { return nil }
        return useLitres ? val : UnitConverter.litresFrom(oz: val)
    }

    /// Constructs SymptomEntry values from the current edit state. Pure — no side effects.
    private static func buildSymptomEntries(
        answers: [String: Bool],
        severities: [String: Int],
        date: Date,
        checkInId: UUID
    ) -> [SymptomEntry] {
        SymptomList.all.map { symptom in
            let present = answers[symptom.id] ?? false
            return SymptomEntry(
                symptomId: symptom.id,
                present: present,
                severity: present && symptom.tracksSeverity ? (severities[symptom.id] ?? 1) : nil,
                date: date,
                checkInId: checkInId
            )
        }
    }
}
