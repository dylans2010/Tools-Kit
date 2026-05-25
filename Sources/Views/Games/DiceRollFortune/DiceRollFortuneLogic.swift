import Foundation

class DiceRollFortuneLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "dice_roll_fortune"
    let baseXPReward = 20
    let winXPBonus = 35
    let baseCoinReward = 0
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: score, gems: 0, badgeUnlocked: nil)
    }
}
