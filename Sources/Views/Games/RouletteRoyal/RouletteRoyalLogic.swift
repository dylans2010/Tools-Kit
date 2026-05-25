import Foundation

class RouletteRoyalLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "roulette_royal"
    let baseXPReward = 25
    let winXPBonus = 0
    let baseCoinReward = 0
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        return GameReward(xp: Int(Double(baseXPReward) * streakMultiplier), coins: score, gems: 0, badgeUnlocked: nil)
    }
}
