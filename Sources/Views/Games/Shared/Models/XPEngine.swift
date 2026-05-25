import Foundation
import UserNotifications

class XPEngine: ObservableObject {
    static let shared = XPEngine()

    func awardXP(amount: Int) {
        var profile = GamesPersistenceManager.shared.load()
        profile.xp += amount

        while profile.xp >= profile.xpToNextLevel {
            profile.xp -= profile.xpToNextLevel
            profile.level += 1
            profile.xpToNextLevel = xpRequired(forLevel: profile.level)

            // Award bonus coins
            let bonus = profile.level * 50
            profile.coins += bonus

            triggerLevelUpNotification(level: profile.level)
            // Notify UI
            NotificationCenter.default.post(name: .levelUp, object: nil, userInfo: ["level": profile.level])
        }

        GamesPersistenceManager.shared.save(profile)
        CurrencyLedger.shared.reload()
    }

    func xpRequired(forLevel level: Int) -> Int {
        return level * 500
    }

    private func triggerLevelUpNotification(level: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Level Up!"
        content.body = "Congratulations! You reached level \(level)."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension NSNotification.Name {
    static let levelUp = NSNotification.Name("levelUp")
}
