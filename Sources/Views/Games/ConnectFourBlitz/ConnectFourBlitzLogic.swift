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
    @Published var losses = 0
    @Published var draws = 0
    @Published var games = 0
    @Published var score = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var lastCol = -1
    @Published var difficulty = 0
    @Published var totalRounds = 5
    @Published var consecutiveWins = 0
    @Published var bestConsecutiveWins = 0

    enum GamePhase { case lobby, playing, results }

    var difficultyName: String {
        switch difficulty { case 0: return "Easy"; case 1: return "Medium"; default: return "Hard" }
    }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        board = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        currentPlayer = 1; gameOver = false; winner = 0; wins = 0; losses = 0; draws = 0; games = 0; score = 0
        consecutiveWins = 0; bestConsecutiveWins = 0
        totalRounds = 5 + difficulty * 2
        phase = .playing
    }

    func dropPiece(col: Int) {
        guard !gameOver, currentPlayer == 1 else { return }
        guard performDrop(col: col, player: 1) else { return }
        lastCol = col
        if checkWin(player: 1) {
            gameOver = true; winner = 1; wins += 1; games += 1; consecutiveWins += 1
            bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
            let moveCount = board.flatMap({ $0 }).filter({ $0 != 0 }).count
            let speedBonus = max(0, (rows * cols - moveCount) * 5)
            score += 100 + speedBonus + (difficulty * 30)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            return
        }
        if isBoardFull() { gameOver = true; winner = 0; draws += 1; games += 1; score += 15; return }
        currentPlayer = 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.aiMove() }
    }

    private func aiMove() {
        switch difficulty {
        case 0: aiMoveEasy()
        case 1: aiMoveMedium()
        default: aiMoveHard()
        }
        if checkWin(player: 2) { gameOver = true; winner = 2; losses += 1; games += 1; consecutiveWins = 0; streakMultiplier = max(1.0, streakMultiplier - 0.1); return }
        if isBoardFull() { gameOver = true; winner = 0; draws += 1; games += 1; score += 15; return }
        currentPlayer = 1
    }

    private func aiMoveEasy() {
        if let randomCol = (0..<cols).filter({ board[0][$0] == 0 }).randomElement() { _ = performDrop(col: randomCol, player: 2) }
    }

    private func aiMoveMedium() {
        if let winCol = findWinningCol(player: 2) { _ = performDrop(col: winCol, player: 2) }
        else if let blockCol = findWinningCol(player: 1) { _ = performDrop(col: blockCol, player: 2) }
        else if board[0][3] == 0 { _ = performDrop(col: 3, player: 2) }
        else if let randomCol = (0..<cols).filter({ board[0][$0] == 0 }).randomElement() { _ = performDrop(col: randomCol, player: 2) }
    }

    private func aiMoveHard() {
        if let winCol = findWinningCol(player: 2) { _ = performDrop(col: winCol, player: 2) }
        else if let blockCol = findWinningCol(player: 1) { _ = performDrop(col: blockCol, player: 2) }
        else if let centerCol = findBestCenterCol() { _ = performDrop(col: centerCol, player: 2) }
        else if let randomCol = (0..<cols).filter({ board[0][$0] == 0 }).randomElement() { _ = performDrop(col: randomCol, player: 2) }
    }

    private func findBestCenterCol() -> Int? {
        let preferredCols = [3, 2, 4, 1, 5, 0, 6]
        return preferredCols.first(where: { board[0][$0] == 0 })
    }

    @discardableResult private func performDrop(col: Int, player: Int) -> Bool {
        for row in stride(from: rows - 1, through: 0, by: -1) {
            if board[row][col] == 0 { board[row][col] = player; return true }
        }
        return false
    }

    private func findWinningCol(player: Int) -> Int? {
        for c in 0..<cols where board[0][c] == 0 {
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
        let diffBonus = difficulty * 20
        var badge: String?
        if wins >= totalRounds { badge = "Connect Four Dominator" }
        if bestConsecutiveWins >= 5 { badge = badge ?? "Connect Streak" }
        if wins > 0 && losses == 0 { badge = badge ?? "Unbeatable" }
        if difficulty >= 2 && wins >= 3 { badge = badge ?? "Connect Four King" }
        let gems = wins >= totalRounds && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: coins, gems: gems, badgeUnlocked: badge)
    }
}
