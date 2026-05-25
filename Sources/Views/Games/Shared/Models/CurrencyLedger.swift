import Foundation

struct InsufficientFundsError: Error, LocalizedError {
    let required: Int
    let available: Int
    let currency: String
    var errorDescription: String? {
        "Insufficient \(currency): need \(required) but only have \(available)"
    }
}

final class CurrencyLedger: ObservableObject {
    static let shared = CurrencyLedger()

    private let lock = NSLock()
    @Published private(set) var profile: PlayerProfile

    private init() {
        profile = GamesPersistenceManager.shared.load()
    }

    func reload() {
        lock.lock()
        profile = GamesPersistenceManager.shared.load()
        lock.unlock()
    }

    func awardCoins(_ amount: Int, reason: String) {
        guard amount > 0 else { return }
        lock.lock()
        profile.coins += amount
        GamesPersistenceManager.shared.save(profile)
        lock.unlock()
    }

    func spendCoins(_ amount: Int) throws {
        lock.lock()
        defer { lock.unlock() }
        guard profile.coins >= amount else {
            throw InsufficientFundsError(required: amount, available: profile.coins, currency: "coins")
        }
        profile.coins -= amount
        GamesPersistenceManager.shared.save(profile)
    }

    func awardGems(_ amount: Int, reason: String) {
        guard amount > 0 else { return }
        lock.lock()
        profile.gems += amount
        GamesPersistenceManager.shared.save(profile)
        lock.unlock()
    }

    func spendGems(_ amount: Int) throws {
        lock.lock()
        defer { lock.unlock() }
        guard profile.gems >= amount else {
            throw InsufficientFundsError(required: amount, available: profile.gems, currency: "gems")
        }
        profile.gems -= amount
        GamesPersistenceManager.shared.save(profile)
    }

    func recordGame(identifier: String, won: Bool, score: Int, reward: GameReward) {
        lock.lock()
        profile.recordGamePlayed(identifier: identifier, won: won, score: score)
        profile.coins += reward.coins
        profile.gems += reward.gems
        if let badge = reward.badgeUnlocked, !profile.unlockedBadges.contains(badge) {
            profile.unlockedBadges.append(badge)
        }
        GamesPersistenceManager.shared.save(profile)
        XPEngine.shared.awardXP(amount: reward.xp)
        profile = GamesPersistenceManager.shared.load()
        lock.unlock()
    }

    func highScore(for gameIdentifier: String) -> Int {
        profile.perGameStats[gameIdentifier]?.highScore ?? 0
    }

    func personalBest(for gameIdentifier: String) -> String? {
        profile.perGameStats[gameIdentifier]?.personalBest
    }
}
