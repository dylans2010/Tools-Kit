import Foundation

class ColorRushLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "color_rush"
    let baseXPReward = 0
    let winXPBonus = 0
    let baseCoinReward = 0
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        return GameReward(xp: Int(Double(score * 5) * streakMultiplier), coins: Int(Double(score * 3) * streakMultiplier), gems: 0, badgeUnlocked: nil)
    }
}
