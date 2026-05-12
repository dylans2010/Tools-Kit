import Foundation
import UserNotifications

@MainActor
final class MailNotificationManager {
    nonisolated(unsafe) static let shared = MailNotificationManager()

    private init() {}

    func requestPermission() async {
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            InternalLogger.shared.log("MailNotificationManager: Permission request failed: \(error.localizedDescription)", level: .error)
        }
    }

    func scheduleNotification(title: String, body: String, accountId: String) {
        // Check if notifications are enabled for this account
        let notificationByAccount = MailSettingsPersistence.loadBoolDictionary(forKey: "mail.settings.notificationsByAccount")
        guard notificationByAccount[accountId] ?? true else { return }

        let importantOnly = UserDefaults.standard.bool(forKey: "mail.settings.importantOnlyNotifications")
        // If importantOnly is true, we might need logic to decide if this message is important.
        // For now, we'll respect the account-level toggle.

        let showPreviews = UserDefaults.standard.bool(forKey: "mail.settings.showNotificationPreviews")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = showPreviews ? body : "You have a new message"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                InternalLogger.shared.log("MailNotificationManager: Error scheduling notification: \(error.localizedDescription)", level: .error)
            }
        }
    }
}
