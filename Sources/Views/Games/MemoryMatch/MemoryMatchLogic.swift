import Foundation

class MemoryMatchLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "memory_match"
    let baseXPReward = 60
    let winXPBonus = 0
    let baseCoinReward = 30
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (score / 5)) * streakMultiplier)
        let coins = Int(Double(baseCoinReward + (score / 10)) * streakMultiplier)
        return GameReward(xp: xp, coins: coins, gems: 0, badgeUnlocked: nil)
    }
}
