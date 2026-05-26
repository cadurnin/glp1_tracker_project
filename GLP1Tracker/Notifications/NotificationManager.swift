import UserNotifications
import Foundation

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let dailyIdentifier = "daily-checkin-reminder"
    private let weeklyIdentifier = "weekly-checkin-reminder"

    override private init() {
        super.init()
        center.delegate = self
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    // timeOfDay is seconds since midnight (e.g. 72000 = 8 PM)
    func scheduleDailyReminder(timeOfDay: TimeInterval) {
        center.removePendingNotificationRequests(withIdentifiers: [dailyIdentifier, weeklyIdentifier])

        let components = secondsToComponents(timeOfDay)

        // Daily reminder
        let dailyContent = UNMutableNotificationContent()
        dailyContent.title = "Time for your daily check-in"
        dailyContent.body = "Tap to log today's symptoms and health data."
        dailyContent.sound = .default
        dailyContent.userInfo = ["destination": "checkIn"]

        var dailyTriggerComponents = components
        dailyTriggerComponents.weekday = nil
        let dailyTrigger = UNCalendarNotificationTrigger(dateMatching: dailyTriggerComponents, repeats: true)
        let dailyRequest = UNNotificationRequest(identifier: dailyIdentifier, content: dailyContent, trigger: dailyTrigger)
        center.add(dailyRequest)

        // Weekly reminder every Sunday
        let weeklyContent = UNMutableNotificationContent()
        weeklyContent.title = "Weekly check-in time"
        weeklyContent.body = "Review your week and update your dose if needed."
        weeklyContent.sound = .default
        weeklyContent.userInfo = ["destination": "weeklyCheckIn"]

        var weeklyComponents = components
        weeklyComponents.weekday = 1 // Sunday
        let weeklyTrigger = UNCalendarNotificationTrigger(dateMatching: weeklyComponents, repeats: true)
        let weeklyRequest = UNNotificationRequest(identifier: weeklyIdentifier, content: weeklyContent, trigger: weeklyTrigger)
        center.add(weeklyRequest)
    }

    // MARK: UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let destination = response.notification.request.content.userInfo["destination"] as? String
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .openDestination,
                object: nil,
                userInfo: ["destination": destination ?? "checkIn"]
            )
        }
        completionHandler()
    }

    // MARK: Helpers

    private func secondsToComponents(_ seconds: TimeInterval) -> DateComponents {
        let totalSeconds = Int(seconds)
        var c = DateComponents()
        c.hour = totalSeconds / 3600
        c.minute = (totalSeconds % 3600) / 60
        c.second = 0
        return c
    }
}

extension Notification.Name {
    static let openDestination = Notification.Name("openDestination")
}
