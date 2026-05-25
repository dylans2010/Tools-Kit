import Foundation

class NumberVaultLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "number_vault"
    let baseXPReward = 55
    let winXPBonus = 0
    let baseCoinReward = 28
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (score * 4)) * streakMultiplier)
        let coins = Int(Double(baseCoinReward + (score * 2)) * streakMultiplier)
        return GameReward(xp: xp, coins: coins, gems: 0, badgeUnlocked: nil)
    }
}
