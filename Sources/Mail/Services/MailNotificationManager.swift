import Foundation
import UserNotifications

@MainActor
final class MailNotificationManager {
    static let shared = MailNotificationManager()

    private init() {}

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func updateAccountNotifications(_ map: [String: Bool]) {
        MailSettingsPersistence.saveBoolDictionary(map, forKey: "mail.settings.notificationsByAccount")
    }

    func shouldNotify(accountId: String, message: MailMessage) -> Bool {
        let accountEnabled = MailRuntimeSettings.notificationsByAccount[accountId] ?? true
        guard accountEnabled else { return false }

        if MailRuntimeSettings.importantOnlyNotifications {
            let body = "\(message.subject) \(message.body)".lowercased()
            return ["urgent", "asap", "deadline", "immediately"].contains { body.contains($0) }
        }

        return true
    }
}
