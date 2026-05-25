import Foundation

class TicTacToeProLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "tic_tac_toe_pro"
    let baseXPReward = 30
    let winXPBonus = 20
    let baseCoinReward = 15
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: Int(Double(baseCoinReward) * streakMultiplier), gems: 0, badgeUnlocked: nil)
    }

    func bestMove(board: [String]) -> Int {
        var bestVal = -1000
        var move = -1

        for i in 0..<9 {
            if board[i] == "" {
                var newBoard = board
                newBoard[i] = "O"
                let moveVal = minimax(board: newBoard, depth: 0, isMax: false)
                if moveVal > bestVal {
                    bestVal = moveVal
                    move = i
                }
            }
        }
        return move
    }

    private func minimax(board: [String], depth: Int, isMax: Bool) -> Int {
        let score = evaluate(board)
        if score == 10 { return score - depth }
        if score == -10 { return score + depth }
        if !board.contains("") { return 0 }

        if isMax {
            var best = -1000
            for i in 0..<9 {
                if board[i] == "" {
                    var b = board
                    b[i] = "O"
                    best = max(best, minimax(board: b, depth: depth + 1, isMax: !isMax))
                }
            }
            return best
        } else {
            var best = 1000
            for i in 0..<9 {
                if board[i] == "" {
                    var b = board
                    b[i] = "X"
                    best = min(best, minimax(board: b, depth: depth + 1, isMax: !isMax))
                }
            }
            return best
        }
    }

    private func evaluate(_ b: [String]) -> Int {
        let wins: [[Int]] = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]
        for w in wins {
            if b[w[0]] != "" && b[w[0]] == b[w[1]] && b[w[1]] == b[w[2]] {
                return b[w[0]] == "O" ? 10 : -10
            }
        }
        return 0
    }
}
