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

    private func populateFields() {
        overallScore = checkIn.overallScore

        if let w = checkIn.weightKg {
            let display = useKg ? w : w / 0.453592
            weightInput = String(format: "%.1f", display)
        }
        if let w = checkIn.waterLitres {
            let display = useLitres ? w : w / 0.0295735
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

    private func save() {
        // Update weight
        if let val = Double(weightInput), val > 0 {
            checkIn.weightKg = useKg ? val : val * 0.453592
        } else if weightInput.isEmpty {
            checkIn.weightKg = nil
        }

        // Update water
        if let val = Double(waterInput), val > 0 {
            checkIn.waterLitres = useLitres ? val : val * 0.0295735
        } else if waterInput.isEmpty {
            checkIn.waterLitres = nil
        }

        checkIn.overallScore = overallScore

        // Update symptoms — delete existing, insert updated
        let existingEntries = checkIn.symptoms
        for entry in existingEntries {
            modelContext.delete(entry)
        }
        checkIn.symptoms.removeAll()

        for symptom in SymptomList.all {
            let present = symptomAnswers[symptom.id] ?? false
            let entry = SymptomEntry(
                symptomId: symptom.id,
                present: present,
                severity: present && symptom.tracksSeverity ? (symptomSeverities[symptom.id] ?? 1) : nil,
                date: checkIn.date,
                checkInId: checkIn.id
            )
            checkIn.symptoms.append(entry)
        }

        dismiss()
    }
}
