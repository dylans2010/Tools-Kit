import Foundation

class SudokuMasterLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "sudoku_master"
    let baseXPReward = 90
    let winXPBonus = 60
    let baseCoinReward = 45
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        let coins = Int(Double(baseCoinReward) * streakMultiplier)
        return GameReward(xp: xp, coins: coins, gems: 0, badgeUnlocked: nil)
    }
}
