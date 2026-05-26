import SwiftUI
import SwiftData
import HealthKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query(sort: \HealthSnapshot.date, order: .reverse) private var snapshots: [HealthSnapshot]
    @Query(sort: \InjectionLog.date, order: .reverse) private var injectionLogs: [InjectionLog]

    @AppStorage("reminderTimeSeconds") private var reminderTimeSeconds: Double = 72000 // 8 PM
    @AppStorage("useKg") private var useKg: Bool = true
    @AppStorage("useLitres") private var useLitres: Bool = true
    @AppStorage("medicationName") private var medicationName: String = ""
    @AppStorage("currentDoseMg") private var currentDoseMg: Double = 0.25
    @AppStorage("injectionDayOfWeek") private var injectionDayOfWeek: Int = 2 // Monday

    @State private var reminderDate: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showShareSheet = false
    @State private var exportURL: URL? = nil
    @State private var hkStatus: HKAuthorizationStatus = .notDetermined
    @State private var requestingHK = false
    @State private var showWeeklyCheckIn = false

    private let doseOptions: [Double] = [0.25, 0.5, 1.0, 1.7, 2.0]
    private let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Reminders
                Section("Reminders") {
                    DatePicker("Daily reminder", selection: $reminderDate, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderDate) { _, new in
                            let seconds = timeSeconds(from: new)
                            reminderTimeSeconds = seconds
                            NotificationManager.shared.scheduleDailyReminder(timeOfDay: seconds)
                        }
                    Picker("Injection day", selection: $injectionDayOfWeek) {
                        ForEach(0..<weekdays.count, id: \.self) { i in
                            Text(weekdays[i]).tag(i)
                        }
                    }
                }

                // MARK: Units
                Section("Units") {
                    Toggle("Use kilograms (kg)", isOn: $useKg)
                    Toggle("Use litres (L)", isOn: $useLitres)
                }

                // MARK: Medication
                Section("Medication") {
                    TextField("Medication name (e.g. Ozempic)", text: $medicationName)
                    Picker("Current dose", selection: $currentDoseMg) {
                        ForEach(doseOptions, id: \.self) { d in
                            Text("\(d, specifier: "%.2f") mg").tag(d)
                        }
                    }
                }

                // MARK: Weekly check-in
                Section("Weekly Review") {
                    Button("Start weekly check-in") {
                        showWeeklyCheckIn = true
                    }
                }

                // MARK: HealthKit
                Section("HealthKit") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(hkStatusText).foregroundStyle(.secondary)
                    }
                    Button(requestingHK ? "Requesting…" : "Re-request HealthKit permissions") {
                        Task {
                            requestingHK = true
                            try? await HealthKitManager.shared.requestAuthorization()
                            updateHKStatus()
                            requestingHK = false
                        }
                    }
                    .disabled(requestingHK)
                }

                // MARK: Export
                Section("Data") {
                    Button("Export to CSV") {
                        exportCSV()
                    }
                    Text("\(checkIns.count) check-ins · \(injectionLogs.count) injections")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                reminderDate = Self.reminderTime(from: reminderTimeSeconds)
                updateHKStatus()
            }
            .sheet(isPresented: $showWeeklyCheckIn) {
                WeeklyCheckInView()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
        }
    }

    // MARK: Helpers

    private func exportCSV() {
        let exporter = CSVExporter()
        if let url = exporter.export(checkIns: checkIns, snapshots: snapshots, injectionLogs: injectionLogs) {
            exportURL = url
            showShareSheet = true
        }
    }

    private func updateHKStatus() {
        let type = HKQuantityType(.bodyMass)
        hkStatus = HealthKitManager.shared.authorizationStatus(for: type)
    }

    private var hkStatusText: String {
        switch hkStatus {
        case .notDetermined: return "Not requested"
        case .sharingDenied: return "Denied"
        case .sharingAuthorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }

    private static func reminderTime(from seconds: Double) -> Date {
        let comps = secondsToComponents(seconds)
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func timeSeconds(from date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double((comps.hour ?? 20) * 3600 + (comps.minute ?? 0) * 60)
    }

    private static func secondsToComponents(_ seconds: Double) -> DateComponents {
        let total = Int(seconds)
        var c = DateComponents()
        c.hour = total / 3600
        c.minute = (total % 3600) / 60
        return c
    }
}

// MARK: Share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
