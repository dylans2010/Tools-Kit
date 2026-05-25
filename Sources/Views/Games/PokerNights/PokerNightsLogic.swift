import Foundation

class PokerNightsLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "poker_nights"
    let baseXPReward = 80
    let winXPBonus = 120
    let baseCoinReward = 0
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: score, gems: won ? 1 : 0, badgeUnlocked: nil)
    }
}
