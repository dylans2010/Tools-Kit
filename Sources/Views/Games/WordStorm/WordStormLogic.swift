import Foundation

class WordStormLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "word_storm"
    let baseXPReward = 70
    let winXPBonus = 0
    let baseCoinReward = 35
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (score * 10)) * streakMultiplier)
        let coins = Int(Double(baseCoinReward + (score * 5)) * streakMultiplier)
        return GameReward(xp: xp, coins: coins, gems: 0, badgeUnlocked: nil)
    }
}
