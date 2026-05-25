import Foundation

class TriviaCrushLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "trivia_crush"
    let baseXPReward = 60
    let winXPBonus = 0
    let baseCoinReward = 30
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (score * 8)) * streakMultiplier)
        let coins = Int(Double(baseCoinReward + (score * 4)) * streakMultiplier)
        return GameReward(xp: xp, coins: coins, gems: score == 10 ? 1 : 0, badgeUnlocked: nil)
    }
}
