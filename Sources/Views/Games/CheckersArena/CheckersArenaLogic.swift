import Foundation

class CheckersArenaLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "checkers_arena"
    let baseXPReward = 70
    let winXPBonus = 50
    let baseCoinReward = 35
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: Int(Double(baseCoinReward) * streakMultiplier), gems: 0, badgeUnlocked: nil)
    }
}
