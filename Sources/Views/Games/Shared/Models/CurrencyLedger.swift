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
        profile.totalCoinsEarned += amount
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
        profile.totalGemsEarned += amount
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
        profile.totalCoinsEarned += reward.coins
        profile.gems += reward.gems
        profile.totalGemsEarned += reward.gems
        if let badge = reward.badgeUnlocked, !profile.unlockedBadges.contains(badge) {
            profile.unlockedBadges.append(badge)
        }

        var stat = profile.perGameStats[identifier] ?? GameStat()
        stat.totalCoinsEarned += reward.coins
        stat.totalXPEarned += reward.xp
        let gamesForLevel = stat.gameLevel * 5
        if stat.gamesPlayed >= gamesForLevel && stat.gameLevel < 50 {
            stat.gameLevel += 1
        }
        profile.perGameStats[identifier] = stat

        checkAchievements(identifier: identifier)

        GamesPersistenceManager.shared.save(profile)
        XPEngine.shared.awardXP(amount: reward.xp)
        profile = GamesPersistenceManager.shared.load()
        lock.unlock()
    }

    func collectDailyBonus() -> (coins: Int, gems: Int) {
        lock.lock()
        defer { lock.unlock() }
        let bonus = profile.collectDailyBonus()
        if bonus.coins > 0 {
            profile.coins += bonus.coins
            profile.totalCoinsEarned += bonus.coins
        }
        if bonus.gems > 0 {
            profile.gems += bonus.gems
            profile.totalGemsEarned += bonus.gems
        }
        GamesPersistenceManager.shared.save(profile)
        return bonus
    }

    func canClaimDailyBonus(for identifier: String) -> Bool {
        profile.isDailyBonusAvailable
    }

    func claimDailyBonus(for identifier: String) {
        _ = collectDailyBonus()
    }

    func highScore(for gameIdentifier: String) -> Int {
        profile.perGameStats[gameIdentifier]?.highScore ?? 0
    }

    func personalBest(for gameIdentifier: String) -> String? {
        profile.perGameStats[gameIdentifier]?.personalBest
    }

    func gameStats(for identifier: String) -> GameStat {
        profile.perGameStats[identifier] ?? GameStat()
    }

    func streakBonus(for identifier: String) -> Double {
        let stat = profile.perGameStats[identifier] ?? GameStat()
        return 1.0 + min(Double(stat.currentStreak) * 0.05, 0.5)
    }

    func dailyStreakMultiplier() -> Double {
        1.0 + min(Double(profile.dailyStreak) * 0.1, 1.0)
    }

    private func checkAchievements(identifier: String) {
        let stat = profile.perGameStats[identifier] ?? GameStat()

        if stat.gamesPlayed >= 10 { profile.addAchievement("play_10_\(identifier)") }
        if stat.gamesPlayed >= 50 { profile.addAchievement("play_50_\(identifier)") }
        if stat.gamesPlayed >= 100 { profile.addAchievement("play_100_\(identifier)") }
        if stat.wins >= 5 { profile.addAchievement("win_5_\(identifier)") }
        if stat.wins >= 25 { profile.addAchievement("win_25_\(identifier)") }
        if stat.bestStreak >= 5 { profile.addAchievement("streak_5_\(identifier)") }
        if stat.bestStreak >= 10 { profile.addAchievement("streak_10_\(identifier)") }
        if stat.gameLevel >= 5 { profile.addAchievement("level_5_\(identifier)") }
        if stat.gameLevel >= 10 { profile.addAchievement("level_10_\(identifier)") }

        if profile.gamesPlayed >= 100 { profile.addAchievement("total_100_games") }
        if profile.totalWins >= 50 { profile.addAchievement("total_50_wins") }
        if profile.dailyStreak >= 7 { profile.addAchievement("week_streak") }
        if profile.dailyStreak >= 30 { profile.addAchievement("month_streak") }
        if profile.totalCoinsEarned >= 10000 { profile.addAchievement("coin_mogul") }
        if profile.level >= 10 { profile.addAchievement("level_10_global") }
        if profile.level >= 25 { profile.addAchievement("level_25_global") }
    }
}
