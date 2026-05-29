import UserNotifications
import Foundation

extension Notification.Name {
    static let openDestination = Notification.Name("openDestination")
}

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    /// Initializes the shared NotificationManager and sets itself as the notification center delegate.
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Requests user permission to send notifications with alert, sound, and badge options.
    /// - Returns: True if authorization was granted, false otherwise.
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Schedules a daily repeating notification at a specified time of day.
    /// Removes any existing "dailyCheckIn" notification before scheduling.
    /// - Parameters:
    ///   - timeOfDay: Time of day in seconds (0 to 86399). Converted to hour:minute components.
    func scheduleDailyReminder(timeOfDay seconds: Double) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyCheckIn"])

        let content = UNMutableNotificationContent()
        content.title = "GLP-1 Check-In"
        content.body = "Time for your daily symptom check-in."
        content.sound = .default

        let totalSeconds = Int(seconds)
        var components = DateComponents()
        components.hour = totalSeconds / 3600
        components.minute = (totalSeconds % 3600) / 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyCheckIn", content: content, trigger: trigger)
        center.add(request)
    }

    /// Schedules a weekly repeating notification for every Sunday at 18:00.
    /// Removes any existing "weeklyCheckIn" notification before scheduling.
    func scheduleSundayReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weeklyCheckIn"])

        let content = UNMutableNotificationContent()
        content.title = "Weekly Check-In"
        content.body = "Time for your weekly GLP-1 progress review."
        content.sound = .default
        content.userInfo = ["destination": "weeklyCheckIn"]

        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklyCheckIn", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handles notification responses when the user taps a notification.
    /// Extracts the "destination" key from userInfo and posts an openDestination notification if present.
    /// - Parameters:
    ///   - center: The notification center that delivered the notification.
    ///   - response: The user's response to the notification.
    ///   - completionHandler: A closure to call when handling is complete.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        let destination = response.notification.request.content.userInfo["destination"] as? String
        NotificationCenter.default.post(
            name: .openDestination,
            object: nil,
            userInfo: destination.map { ["destination": $0] }
        )
        completionHandler()
    }

    /// Handles notifications that arrive while the app is in the foreground.
    /// Displays notifications as a banner with sound when the app is active.
    /// - Parameters:
    ///   - center: The notification center that delivered the notification.
    ///   - notification: The notification that arrived while the app was in the foreground.
    ///   - completionHandler: A closure to call with presentation options.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
