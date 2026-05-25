import Foundation

class ConnectFourBlitzLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "connect_four_blitz"
    let baseXPReward = 45
    let winXPBonus = 30
    let baseCoinReward = 22
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: Int(Double(baseCoinReward) * streakMultiplier), gems: 0, badgeUnlocked: nil)
    }

    func checkWin(board: [[Int]]) -> Bool {
        // Check rows
        for r in 0..<6 {
            for c in 0..<4 {
                if board[r][c] != 0 && board[r][c] == board[r][c+1] && board[r][c] == board[r][c+2] && board[r][c] == board[r][c+3] { return true }
            }
        }
        // Check cols
        for c in 0..<7 {
            for r in 0..<3 {
                if board[r][c] != 0 && board[r][c] == board[r+1][c] && board[r][c] == board[r+2][c] && board[r][c] == board[r+3][c] { return true }
            }
        }
        return false
    }
}
