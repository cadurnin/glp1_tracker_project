import SwiftUI
import SwiftData

@main
struct GLP1TrackerApp: App {
    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer = false

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyCheckIn.self,
            WeeklyCheckIn.self,
            SymptomEntry.self,
            InjectionLog.self,
            HealthSnapshot.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasSeenDisclaimer {
                MainTabView()
                    .task { await setup() }
            } else {
                DisclaimerView {
                    hasSeenDisclaimer = true
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func setup() async {
        try? await HealthKitManager.shared.requestAuthorization()
        _ = await NotificationManager.shared.requestPermission()
        let seconds = UserDefaults.standard.double(forKey: "reminderTimeSeconds")
        NotificationManager.shared.scheduleDailyReminder(timeOfDay: seconds > 0 ? seconds : 72000)
    }
}

// MARK: - Disclaimer

struct DisclaimerView: View {
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "cross.case.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("GLP-1 Tracker")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 16) {
                Text("Medical Disclaimer")
                    .font(.headline)
                Text("""
                    This app is a personal tracking tool only. It is not a medical device and does not provide medical advice.

                    All warnings shown are informational prompts to consult your healthcare provider — they are not a diagnosis.

                    Always follow the guidance of your prescribing physician.
                    """)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

            Button {
                onAccept()
            } label: {
                Text("I Understand")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }
}
