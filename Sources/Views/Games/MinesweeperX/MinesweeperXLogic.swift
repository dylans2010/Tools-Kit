import Foundation

class MinesweeperXLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "minesweeper_x"
    let baseXPReward = 80
    let winXPBonus = 50
    let baseCoinReward = 40
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: Int(Double(baseCoinReward) * streakMultiplier), gems: 0, badgeUnlocked: nil)
    }
}
