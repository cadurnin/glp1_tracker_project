import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var checkIns: [DailyCheckIn]
    @Query private var weeklyCheckIns: [WeeklyCheckIn]
    @Query private var injectionLogs: [InjectionLog]
    @Query private var snapshots: [HealthSnapshot]

    @AppStorage("useKg") private var useKg = true
    @AppStorage("useLitres") private var useLitres = true
    @AppStorage("reminderTimeSeconds") private var reminderTimeSeconds = 72000.0

    @State private var reminderDate = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showWeeklyCheckIn = false
    @State private var exportFile: CSVExportFile?
    @State private var showExportErrorAlert = false
    @State private var showDeleteAllAlert = false
    @State private var showDeleteAllConfirmAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Units
                Section("Units") {
                    Toggle("Use Kilograms (kg)", isOn: $useKg)
                    Toggle("Use Litres (L)", isOn: $useLitres)
                }

                // MARK: Reminder
                Section("Daily Reminder") {
                    DatePicker("Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderDate) { _, newVal in
                            let seconds = newVal.timeIntervalSince(Calendar.current.startOfDay(for: newVal))
                            reminderTimeSeconds = seconds
                            NotificationManager.shared.scheduleDailyReminder(timeOfDay: seconds)
                        }
                }

                // MARK: Weekly check-in
                Section("Weekly") {
                    Button("Start Weekly Check-In") {
                        showWeeklyCheckIn = true
                    }
                }

                // MARK: HealthKit
                Section("Apple Health") {
                    Button("Re-request HealthKit Access") {
                        Task {
                            try? await HealthKitManager.shared.requestAuthorization()
                        }
                    }
                }

                // MARK: Export
                Section("Data") {
                    Button("Export as CSV") {
                        exportCSV()
                    }
                }

                // MARK: Delete All
                Section {
                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash.fill")
                    }
                } footer: {
                    Text("This permanently deletes all check-ins, injection logs, and health snapshots. This cannot be undone.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showWeeklyCheckIn) {
                WeeklyCheckInView()
            }
            .sheet(item: $exportFile) { file in
                ShareSheet(items: [file.url])
            }
            .alert("Export Failed", isPresented: $showExportErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Could not create the CSV file. Please try again.")
            }
            // First alert — confirm intent
            .alert("Delete All Data?", isPresented: $showDeleteAllAlert) {
                Button("Delete Everything", role: .destructive) {
                    showDeleteAllConfirmAlert = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(checkIns.count) daily check-in(s), \(weeklyCheckIns.count) weekly check-in(s), \(injectionLogs.count) injection log(s), and \(snapshots.count) health snapshot(s).\n\nThis action cannot be undone.")
            }
            // Second alert — double-confirm
            .alert("Are you absolutely sure?", isPresented: $showDeleteAllConfirmAlert) {
                Button("Yes, Delete Everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All your data will be permanently removed from this device.")
            }
        }
        .onAppear {
            let seconds = reminderTimeSeconds
            if seconds > 0 {
                let today = Calendar.current.startOfDay(for: Date())
                reminderDate = Date(timeInterval: seconds, since: today)
            }
        }
    }

    // MARK: - Actions

    private func exportCSV() {
        let csv = CSVExporter.export(checkIns: checkIns)
        let fileName = "GLP1Tracker_\(Date().formatted(.iso8601.year().month().day())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            exportFile = CSVExportFile(url: url)
        } catch {
            exportFile = nil
            showExportErrorAlert = true
        }
    }

    private func deleteAllData() {
        for item in checkIns { modelContext.delete(item) }
        for item in weeklyCheckIns { modelContext.delete(item) }
        for item in injectionLogs { modelContext.delete(item) }
        for item in snapshots { modelContext.delete(item) }
    }

    private struct CSVExportFile: Identifiable {
        let id = UUID()
        let url: URL
    }
}
