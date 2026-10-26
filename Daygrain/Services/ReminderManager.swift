import Foundation
import UserNotifications

enum ReminderManager {
    static let identifier = "stillnote.daily-reflection"

    static func schedule(hour: Int, minute: Int) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        guard granted else {
            throw JournalError.persistence("Notifications are disabled. You can allow them in iPhone Settings, then turn on your reminder here.")
        }
        let content = UNMutableNotificationContent()
        content.title = "A little of the day, kept."
        content.body = "A detail, a feeling, a page of your own. Return to Daygrain."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
