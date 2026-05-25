import Foundation

class TacticalRaidLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "tactical_raid"
    let baseXPReward = 100
    let winXPBonus = 70
    let baseCoinReward = 50
    let winCoinBonus = 30

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: coins, gems: won ? 1 : 0, badgeUnlocked: nil)
    }
}
