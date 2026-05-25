import Foundation

final class OthelloFlipLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "othello_flip"
    let baseXPReward = 25; let winXPBonus = 20; let baseCoinReward = 15; let winCoinBonus = 10

    enum GamePhase { case lobby, playing, results }
    enum Piece: Int { case empty = 0, black = 1, white = 2 }

    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var board: [[Piece]] = []; @Published var currentPlayer: Piece = .black
    @Published var won = false; @Published var playerPieces = 2; @Published var aiPieces = 2
    @Published var moveCount = 0; @Published var flipsThisTurn = 0; @Published var bestFlip = 0

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; score = 0; moveCount = 0; flipsThisTurn = 0; bestFlip = 0
        streakMultiplier = 1.0; won = false; currentPlayer = .black
        board = Array(repeating: Array(repeating: Piece.empty, count: 8), count: 8)
        board[3][3] = .white; board[3][4] = .black; board[4][3] = .black; board[4][4] = .white
        updateCounts(); phase = .playing
    }

    func placePiece(row: Int, col: Int) {
        guard currentPlayer == .black, board[row][col] == .empty else { return }
        let flipped = getFlips(row: row, col: col, player: .black)
        guard !flipped.isEmpty else { return }
        board[row][col] = .black; moveCount += 1
        for (r, c) in flipped { board[r][c] = .black }
        flipsThisTurn = flipped.count; bestFlip = max(bestFlip, flipped.count)
        score += Int(Double(flipped.count * 20 + 10) * streakMultiplier)
        streakMultiplier = min(3.0, streakMultiplier + Double(flipped.count) * 0.05)
        updateCounts(); currentPlayer = .white
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.aiMove() }
    }

    private func aiMove() {
        let moves = allValidMoves(for: .white)
        guard !moves.isEmpty else { currentPlayer = .black; checkEnd(); return }
        let move: (Int, Int)
        if difficulty >= 2 { move = moves.max(by: { getFlips(row: $0.0, col: $0.1, player: .white).count < getFlips(row: $1.0, col: $1.1, player: .white).count })! }
        else if difficulty == 1 { move = moves.count > 2 ? moves.sorted(by: { getFlips(row: $0.0, col: $0.1, player: .white).count > getFlips(row: $1.0, col: $1.1, player: .white).count })[Int.random(in: 0..<min(3, moves.count))] : moves.randomElement()! }
        else { move = moves.randomElement()! }
        board[move.0][move.1] = .white
        for (r, c) in getFlips(row: move.0, col: move.1, player: .white) { board[r][c] = .white }
        updateCounts(); currentPlayer = .black; checkEnd()
    }

    private func getFlips(row: Int, col: Int, player: Piece) -> [(Int, Int)] {
        let opp: Piece = player == .black ? .white : .black
        var all: [(Int, Int)] = []
        for (dr, dc) in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)] {
            var flips: [(Int, Int)] = []; var r = row + dr; var c = col + dc
            while r >= 0 && r < 8 && c >= 0 && c < 8 && board[r][c] == opp {
                flips.append((r, c)); r += dr; c += dc
            }
            if r >= 0 && r < 8 && c >= 0 && c < 8 && board[r][c] == player && !flips.isEmpty { all += flips }
        }
        return all
    }

    private func allValidMoves(for player: Piece) -> [(Int, Int)] {
        var moves: [(Int, Int)] = []
        for r in 0..<8 { for c in 0..<8 { if board[r][c] == .empty && !getFlips(row: r, col: c, player: player).isEmpty { moves.append((r, c)) } } }
        return moves
    }

    private func updateCounts() {
        playerPieces = board.flatMap { $0 }.filter { $0 == .black }.count
        aiPieces = board.flatMap { $0 }.filter { $0 == .white }.count
    }

    private func checkEnd() {
        if allValidMoves(for: .black).isEmpty && allValidMoves(for: .white).isEmpty {
            won = playerPieces > aiPieces; phase = .results
        }
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if won && playerPieces >= 40 { badge = "Othello Dominator" }
        if bestFlip >= 6 { badge = badge ?? "Mega Flip" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
