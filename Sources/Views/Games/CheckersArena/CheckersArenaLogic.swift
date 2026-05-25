import Foundation

struct CheckerPiece: Equatable {
    let player: Int
    var isKing: Bool = false
}

final class CheckersArenaLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "checkers_arena"
    let baseXPReward = 60
    let winXPBonus = 50
    let baseCoinReward = 30
    let winCoinBonus = 20

    @Published var board: [[CheckerPiece?]] = []
    @Published var selectedPos: (row: Int, col: Int)?
    @Published var validMoves: [(row: Int, col: Int)] = []
    @Published var currentPlayer = 1
    @Published var gameOver = false
    @Published var winner = 0
    @Published var score = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        board = Array(repeating: Array(repeating: nil as CheckerPiece?, count: 8), count: 8)
        for r in 0..<3 { for c in 0..<8 { if (r + c) % 2 == 1 { board[r][c] = CheckerPiece(player: 2) } } }
        for r in 5..<8 { for c in 0..<8 { if (r + c) % 2 == 1 { board[r][c] = CheckerPiece(player: 1) } } }
        currentPlayer = 1; gameOver = false; winner = 0; score = 0; selectedPos = nil; validMoves = []
        phase = .playing
    }

    func selectCell(row: Int, col: Int) {
        guard !gameOver, currentPlayer == 1 else { return }
        if let sel = selectedPos, validMoves.contains(where: { $0.row == row && $0.col == col }) {
            movePiece(from: sel, to: (row, col))
            return
        }
        if let piece = board[row][col], piece.player == 1 {
            selectedPos = (row, col)
            validMoves = getValidMoves(from: (row, col), player: 1)
        }
    }

    private func movePiece(from: (row: Int, col: Int), to: (row: Int, col: Int)) {
        var piece = board[from.row][from.col]!
        board[from.row][from.col] = nil
        let dr = to.row - from.row; let dc = to.col - from.col
        if abs(dr) == 2 {
            let mr = from.row + dr / 2; let mc = from.col + dc / 2
            board[mr][mc] = nil; score += 20
        }
        if (piece.player == 1 && to.row == 0) || (piece.player == 2 && to.row == 7) { piece.isKing = true; score += 10 }
        board[to.row][to.col] = piece
        selectedPos = nil; validMoves = []
        if checkGameOver() { return }
        currentPlayer = 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.aiTurn() }
    }

    private func aiTurn() {
        var allMoves: [(from: (Int, Int), to: (Int, Int))] = []
        for r in 0..<8 { for c in 0..<8 {
            if let piece = board[r][c], piece.player == 2 {
                for m in getValidMoves(from: (r, c), player: 2) { allMoves.append((from: (r, c), to: (r: m.row, c: m.col))) }
            }
        }}
        let jumps = allMoves.filter { abs($0.from.0 - $0.to.0) == 2 }
        if let move = (jumps.isEmpty ? allMoves : jumps).randomElement() {
            var piece = board[move.from.0][move.from.1]!
            board[move.from.0][move.from.1] = nil
            if abs(move.from.0 - move.to.0) == 2 {
                let mr = (move.from.0 + move.to.0) / 2; let mc = (move.from.1 + move.to.1) / 2
                board[mr][mc] = nil
            }
            if piece.player == 2 && move.to.0 == 7 { piece.isKing = true }
            board[move.to.0][move.to.1] = piece
        }
        if checkGameOver() { return }
        currentPlayer = 1
    }

    private func getValidMoves(from pos: (row: Int, col: Int), player: Int) -> [(row: Int, col: Int)] {
        guard let piece = board[pos.row][pos.col] else { return [] }
        var moves: [(row: Int, col: Int)] = []
        let dirs: [(Int, Int)] = piece.isKing ? [(-1,-1),(-1,1),(1,-1),(1,1)] : (player == 1 ? [(-1,-1),(-1,1)] : [(1,-1),(1,1)])
        for (dr, dc) in dirs {
            let nr = pos.row + dr; let nc = pos.col + dc
            if nr >= 0 && nr < 8 && nc >= 0 && nc < 8 {
                if board[nr][nc] == nil { moves.append((nr, nc)) }
                else if let other = board[nr][nc], other.player != player {
                    let jr = nr + dr; let jc = nc + dc
                    if jr >= 0 && jr < 8 && jc >= 0 && jc < 8 && board[jr][jc] == nil { moves.append((jr, jc)) }
                }
            }
        }
        return moves
    }

    private func checkGameOver() -> Bool {
        let p1 = board.flatMap { $0 }.compactMap { $0 }.filter { $0.player == 1 }.count
        let p2 = board.flatMap { $0 }.compactMap { $0 }.filter { $0.player == 2 }.count
        if p1 == 0 { gameOver = true; winner = 2; phase = .results; streakMultiplier = 1.0; return true }
        if p2 == 0 { gameOver = true; winner = 1; score += 50; phase = .results; streakMultiplier = min(3.0, streakMultiplier + 0.1); return true }
        return false
    }

    func finalReward() -> GameReward {
        let won = winner == 1
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let coins = baseCoinReward + (won ? winCoinBonus : 0)
        return GameReward(xp: max(1, xp), coins: coins, gems: 0, badgeUnlocked: won ? "Checker Champion" : nil)
    }
}
