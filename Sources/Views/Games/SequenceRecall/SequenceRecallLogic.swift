import Foundation

class SequenceRecallLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "sequence_recall"
    let baseXPReward = 50
    let winXPBonus = 0
    let baseCoinReward = 25
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (score * 5)) * streakMultiplier)
        let coins = Int(Double(baseCoinReward + (score * 2)) * streakMultiplier)
        return GameReward(xp: xp, coins: coins, gems: 0, badgeUnlocked: nil)
    }
}
