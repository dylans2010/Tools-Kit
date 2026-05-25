import Foundation

class ScratchAndWinLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "scratch_and_win"
    let baseXPReward = 15
    let winXPBonus = 0
    let baseCoinReward = 0
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        return GameReward(xp: Int(Double(baseXPReward) * streakMultiplier), coins: score, gems: 0, badgeUnlocked: nil)
    }
}
