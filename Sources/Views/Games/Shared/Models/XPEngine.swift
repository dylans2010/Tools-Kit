import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

final class XPEngine: ObservableObject {
    static let shared = XPEngine()

    @Published var didLevelUp = false
    @Published var newLevel = 1
    @Published var bonusCoinsAwarded = 0

    private init() {}

    static func xpRequired(forLevel level: Int) -> Int {
        level * 500
    }

    func awardXP(amount: Int) {
        guard amount > 0 else { return }
        var profile = GamesPersistenceManager.shared.load()
        var remaining = amount
        var leveledUp = false
        var totalBonusCoins = 0

        while remaining > 0 {
            let needed = profile.xpToNextLevel - profile.xp
            if remaining >= needed {
                remaining -= needed
                profile.level += 1
                profile.xp = 0
                profile.xpToNextLevel = XPEngine.xpRequired(forLevel: profile.level)
                let bonus = profile.level * 50
                profile.coins += bonus
                totalBonusCoins += bonus
                leveledUp = true
            } else {
                profile.xp += remaining
                remaining = 0
            }
        }

        GamesPersistenceManager.shared.save(profile)

        if leveledUp {
            didLevelUp = true
            newLevel = profile.level
            bonusCoinsAwarded = totalBonusCoins
            sendBackgroundLevelUpNotification(level: profile.level)
        }
    }

    func clearLevelUp() {
        didLevelUp = false
    }

    private func sendBackgroundLevelUpNotification(level: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Level Up!"
        content.body = "You reached Level \(level)! Bonus coins awarded."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "levelUp_\(level)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
