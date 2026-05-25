import Foundation

final class ConnectFourBlitzLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "connect_four_blitz"
    let baseXPReward = 50
    let winXPBonus = 40
    let baseCoinReward = 25
    let winCoinBonus = 15

    let rows = 6, cols = 7
    @Published var board: [[Int]] = []
    @Published var currentPlayer = 1
    @Published var gameOver = false
    @Published var winner = 0
    @Published var wins = 0
    @Published var games = 0
    @Published var score = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var lastCol = -1

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        board = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        currentPlayer = 1; gameOver = false; winner = 0; wins = 0; games = 0; score = 0; phase = .playing
    }

    func dropPiece(col: Int) {
        guard !gameOver, currentPlayer == 1 else { return }
        guard performDrop(col: col, player: 1) else { return }
        lastCol = col
        if checkWin(player: 1) { gameOver = true; winner = 1; wins += 1; score += 100; games += 1; streakMultiplier = min(3.0, streakMultiplier + 0.1); return }
        if isBoardFull() { gameOver = true; winner = 0; games += 1; return }
        currentPlayer = 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.aiMove() }
    }

    private func aiMove() {
        if let winCol = findWinningCol(player: 2) { _ = performDrop(col: winCol, player: 2) }
        else if let blockCol = findWinningCol(player: 1) { _ = performDrop(col: blockCol, player: 2) }
        else if board[0][3] == 0 { _ = performDrop(col: 3, player: 2) }
        else if let randomCol = (0..<cols).filter({ board[0][$0] == 0 }).randomElement() { _ = performDrop(col: randomCol, player: 2) }

        if checkWin(player: 2) { gameOver = true; winner = 2; games += 1; streakMultiplier = 1.0; return }
        if isBoardFull() { gameOver = true; winner = 0; games += 1; return }
        currentPlayer = 1
    }

    @discardableResult private func performDrop(col: Int, player: Int) -> Bool {
        for row in stride(from: rows - 1, through: 0, by: -1) {
            if board[row][col] == 0 { board[row][col] = player; return true }
        }
        return false
    }

    private func findWinningCol(player: Int) -> Int? {
        for c in 0..<cols {
            var testBoard = board
            for r in stride(from: rows - 1, through: 0, by: -1) {
                if testBoard[r][c] == 0 { testBoard[r][c] = player; break }
            }
            if checkWinOnBoard(testBoard, player: player) { return c }
        }
        return nil
    }

    private func checkWin(player: Int) -> Bool { checkWinOnBoard(board, player: player) }

    private func checkWinOnBoard(_ b: [[Int]], player: Int) -> Bool {
        for r in 0..<rows { for c in 0..<cols {
            if c + 3 < cols && (0..<4).allSatisfy({ b[r][c + $0] == player }) { return true }
            if r + 3 < rows && (0..<4).allSatisfy({ b[r + $0][c] == player }) { return true }
            if r + 3 < rows && c + 3 < cols && (0..<4).allSatisfy({ b[r + $0][c + $0] == player }) { return true }
            if r + 3 < rows && c - 3 >= 0 && (0..<4).allSatisfy({ b[r + $0][c - $0] == player }) { return true }
        }}
        return false
    }

    private func isBoardFull() -> Bool { board[0].allSatisfy { $0 != 0 } }

    func newRound() { board = Array(repeating: Array(repeating: 0, count: cols), count: rows); currentPlayer = 1; gameOver = false; winner = 0 }
    func endSession() { phase = .results }

    func finalReward() -> GameReward {
        let won = wins > 0
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let coins = baseCoinReward + (won ? winCoinBonus * wins : 0)
        return GameReward(xp: max(1, xp), coins: coins, gems: 0, badgeUnlocked: wins >= 5 ? "Connect Four King" : nil)
    }
}
