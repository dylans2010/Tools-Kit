import Foundation

final class DominoesLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "dominoes"
    let baseXPReward = 25; let winXPBonus = 20; let baseCoinReward = 15; let winCoinBonus = 10

    enum GamePhase { case lobby, playing, results }
    enum CellState: Int { case empty = 0, player = 1, ai = 2 }

    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var boardSize = 7; @Published var board: [[CellState]] = []
    @Published var currentTurn: CellState = .player; @Published var won = false
    @Published var moveCount = 0; @Published var playerCaptures = 0; @Published var aiCaptures = 0
    @Published var consecutiveWins = 0; @Published var bestStreak = 0

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; boardSize = 7 + difficulty * 2
        score = 0; moveCount = 0; playerCaptures = 0; aiCaptures = 0; won = false
        consecutiveWins = 0; bestStreak = 0; streakMultiplier = 1.0; currentTurn = .player
        board = Array(repeating: Array(repeating: CellState.empty, count: boardSize), count: boardSize)
        phase = .playing
    }

    func placeAt(row: Int, col: Int) {
        guard row < boardSize, col < boardSize, board[row][col] == .empty, currentTurn == .player else { return }
        board[row][col] = .player; moveCount += 1
        let captured = checkCaptures(row: row, col: col, player: .player)
        playerCaptures += captured
        score += Int(Double(20 + captured * 30 + difficulty * 10) * streakMultiplier)
        if captured > 0 { streakMultiplier = min(3.0, streakMultiplier + 0.1) }
        if checkWin(.player) { won = true; consecutiveWins += 1; bestStreak = max(bestStreak, consecutiveWins); phase = .results; return }
        currentTurn = .ai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.aiMove() }
    }

    private func aiMove() {
        var bestMove: (Int, Int)?; var bestScore = -1
        for r in 0..<boardSize { for c in 0..<boardSize {
            if board[r][c] == .empty {
                let s = evaluateMove(r, c)
                if s > bestScore || (s == bestScore && Bool.random()) { bestScore = s; bestMove = (r, c) }
            }
        } }
        if let (r, c) = bestMove {
            board[r][c] = .ai
            let captured = checkCaptures(row: r, col: c, player: .ai)
            aiCaptures += captured
            if checkWin(.ai) { won = false; phase = .results; return }
        }
        currentTurn = .player
        if !hasValidMoves() { won = playerCaptures > aiCaptures; phase = .results }
    }

    private func evaluateMove(_ r: Int, _ c: Int) -> Int {
        var s = 0
        if difficulty >= 1 {
            let dirs = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]
            for (dr, dc) in dirs {
                let nr = r + dr; let nc = c + dc
                if nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize && board[nr][nc] == .player { s += 2 }
            }
        }
        if (r == 0 || r == boardSize - 1) && (c == 0 || c == boardSize - 1) { s += 5 }
        return s + Int.random(in: 0...(2 - difficulty))
    }

    private func checkCaptures(row: Int, col: Int, player: CellState) -> Int {
        let opp: CellState = player == .player ? .ai : .player
        var captured = 0
        for (dr, dc) in [(-1,0),(1,0),(0,-1),(0,1)] {
            let nr = row + dr; let nc = col + dc
            if nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize && board[nr][nc] == opp {
                let nnr = nr + dr; let nnc = nc + dc
                if nnr >= 0 && nnr < boardSize && nnc >= 0 && nnc < boardSize && board[nnr][nnc] == player {
                    board[nr][nc] = .empty; captured += 1
                }
            }
        }
        return captured
    }

    private func checkWin(_ player: CellState) -> Bool {
        let count = board.flatMap { $0 }.filter { $0 == player }.count
        return count >= boardSize * 2
    }

    private func hasValidMoves() -> Bool {
        board.flatMap { $0 }.contains(.empty)
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if won { badge = "Dominoes Champion" }
        if playerCaptures >= 10 { badge = badge ?? "Capture King" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
