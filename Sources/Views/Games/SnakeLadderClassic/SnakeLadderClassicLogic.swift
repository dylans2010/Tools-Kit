import Foundation

class SnakeLadderClassicLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "snake_ladder_classic"
    let baseXPReward = 50
    let winXPBonus = 40
    let baseCoinReward = 25
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: Int(Double(baseCoinReward) * streakMultiplier), gems: 0, badgeUnlocked: nil)
    }
}
