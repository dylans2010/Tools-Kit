import Foundation
import SwiftUI

class CurrencyLedger: ObservableObject {
    static let shared = CurrencyLedger()

    @Published private(set) var profile: PlayerProfile

    private init() {
        self.profile = GamesPersistenceManager.shared.load()
    }

    func awardCoins(_ amount: Int, reason: String) {
        profile.coins += amount
        GamesPersistenceManager.shared.save(profile)
        objectWillChange.send()
    }

    func spendCoins(_ amount: Int) throws {
        guard profile.coins >= amount else {
            throw InsufficientFundsError.coins
        }
        profile.coins -= amount
        GamesPersistenceManager.shared.save(profile)
        objectWillChange.send()
    }

    func awardGems(_ amount: Int, reason: String) {
        profile.gems += amount
        GamesPersistenceManager.shared.save(profile)
        objectWillChange.send()
    }

    func spendGems(_ amount: Int) throws {
        guard profile.gems >= amount else {
            throw InsufficientFundsError.gems
        }
        profile.gems -= amount
        GamesPersistenceManager.shared.save(profile)
        objectWillChange.send()
    }

    func updateStats(gameID: String, score: Int, won: Bool) {
        profile.gamesPlayed += 1
        if won { profile.totalWins += 1 }

        var stat = profile.perGameStats[gameID] ?? GameStat(highScore: 0, gamesPlayed: 0, wins: 0)
        stat.gamesPlayed += 1
        if won { stat.wins += 1 }
        if score > stat.highScore {
            stat.highScore = score
            stat.personalBest = "\(score)"
        }
        profile.perGameStats[gameID] = stat

        GamesPersistenceManager.shared.save(profile)
        objectWillChange.send()
    }

    func reload() {
        self.profile = GamesPersistenceManager.shared.load()
    }
}

enum InsufficientFundsError: Error {
    case coins
    case gems
}
