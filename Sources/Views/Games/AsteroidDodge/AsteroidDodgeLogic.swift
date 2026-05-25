import Foundation

class AsteroidDodgeLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "asteroid_dodge"
    let baseXPReward = 0
    let winXPBonus = 0
    let baseCoinReward = 0
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        return GameReward(xp: Int(Double(score) * streakMultiplier), coins: Int(Double(score / 5) * streakMultiplier), gems: 0, badgeUnlocked: nil)
    }
}
