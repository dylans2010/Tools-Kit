import Foundation

struct ChessPiece: Equatable {
    enum PieceType: String { case king, queen, rook, bishop, knight, pawn }
    let type: PieceType
    let color: Int
    var hasMoved: Bool = false

    var symbol: String {
        let symbols: [PieceType: (String, String)] = [.king: ("♔","♚"), .queen: ("♕","♛"), .rook: ("♖","♜"), .bishop: ("♗","♝"), .knight: ("♘","♞"), .pawn: ("♙","♟")]
        return color == 1 ? symbols[type]!.0 : symbols[type]!.1
    }
}

final class ChessLiteLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "chess_lite"
    let baseXPReward = 100
    let winXPBonus = 80
    let baseCoinReward = 50
    let winCoinBonus = 30

    @Published var board: [[ChessPiece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    @Published var selectedPos: (row: Int, col: Int)?
    @Published var validMoves: [(row: Int, col: Int)] = []
    @Published var currentPlayer = 1
    @Published var gameOver = false
    @Published var winner = 0
    @Published var capturedByPlayer: [ChessPiece] = []
    @Published var capturedByAI: [ChessPiece] = []
    @Published var score = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var moveCount = 0

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        setupBoard(); currentPlayer = 1; gameOver = false; winner = 0; score = 0; moveCount = 0
        capturedByPlayer = []; capturedByAI = []; selectedPos = nil; validMoves = []; phase = .playing
    }

    private func setupBoard() {
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        let backRow: [ChessPiece.PieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for c in 0..<8 {
            board[0][c] = ChessPiece(type: backRow[c], color: 2)
            board[1][c] = ChessPiece(type: .pawn, color: 2)
            board[6][c] = ChessPiece(type: .pawn, color: 1)
            board[7][c] = ChessPiece(type: backRow[c], color: 1)
        }
    }

    func selectCell(row: Int, col: Int) {
        guard !gameOver, currentPlayer == 1 else { return }
        if let _ = selectedPos, validMoves.contains(where: { $0.row == row && $0.col == col }) {
            makeMove(from: selectedPos!, to: (row, col)); return
        }
        if let piece = board[row][col], piece.color == 1 {
            selectedPos = (row, col); validMoves = getBasicMoves(from: (row, col))
        } else { selectedPos = nil; validMoves = [] }
    }

    private func makeMove(from: (row: Int, col: Int), to: (row: Int, col: Int)) {
        if let captured = board[to.row][to.col] {
            if currentPlayer == 1 { capturedByPlayer.append(captured); score += pieceValue(captured.type) }
            else { capturedByAI.append(captured) }
            if captured.type == .king { gameOver = true; winner = currentPlayer; phase = .results; if currentPlayer == 1 { score += 200 }; return }
        }
        var piece = board[from.row][from.col]!; piece.hasMoved = true
        if piece.type == .pawn && (to.row == 0 || to.row == 7) { piece = ChessPiece(type: .queen, color: piece.color, hasMoved: true); score += 50 }
        board[to.row][to.col] = piece; board[from.row][from.col] = nil
        selectedPos = nil; validMoves = []; moveCount += 1
        currentPlayer = currentPlayer == 1 ? 2 : 1
        if currentPlayer == 2 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in self?.aiTurn() } }
    }

    private func aiTurn() {
        var allMoves: [(from: (Int, Int), to: (Int, Int), value: Int)] = []
        for r in 0..<8 { for c in 0..<8 {
            if let piece = board[r][c], piece.color == 2 {
                for m in getBasicMoves(from: (r, c)) {
                    let val = board[m.row][m.col].map { pieceValue($0.type) } ?? 0
                    allMoves.append((from: (r, c), to: (m.row, m.col), value: val))
                }
            }
        }}
        let captures = allMoves.filter { $0.value > 0 }.sorted { $0.value > $1.value }
        if let best = captures.first { makeMove(from: best.from, to: best.to) }
        else if let random = allMoves.randomElement() { makeMove(from: random.from, to: random.to) }
        else { gameOver = true; winner = 1; score += 100; phase = .results }
    }

    private func getBasicMoves(from pos: (row: Int, col: Int)) -> [(row: Int, col: Int)] {
        guard let piece = board[pos.row][pos.col] else { return [] }
        var moves: [(row: Int, col: Int)] = []
        switch piece.type {
        case .pawn:
            let dir = piece.color == 1 ? -1 : 1
            let nr = pos.row + dir
            if nr >= 0 && nr < 8 && board[nr][pos.col] == nil { moves.append((nr, pos.col))
                if !piece.hasMoved { let nr2 = pos.row + dir * 2; if nr2 >= 0 && nr2 < 8 && board[nr2][pos.col] == nil { moves.append((nr2, pos.col)) } }
            }
            for dc in [-1, 1] { let nc = pos.col + dc; if nr >= 0 && nr < 8 && nc >= 0 && nc < 8 { if let t = board[nr][nc], t.color != piece.color { moves.append((nr, nc)) } } }
        case .knight:
            for (dr, dc) in [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)] {
                let nr = pos.row + dr; let nc = pos.col + dc
                if nr >= 0 && nr < 8 && nc >= 0 && nc < 8 { if board[nr][nc] == nil || board[nr][nc]!.color != piece.color { moves.append((nr, nc)) } }
            }
        case .bishop: moves = slidingMoves(from: pos, dirs: [(-1,-1),(-1,1),(1,-1),(1,1)], color: piece.color)
        case .rook: moves = slidingMoves(from: pos, dirs: [(-1,0),(1,0),(0,-1),(0,1)], color: piece.color)
        case .queen: moves = slidingMoves(from: pos, dirs: [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)], color: piece.color)
        case .king:
            for dr in -1...1 { for dc in -1...1 { if dr == 0 && dc == 0 { continue }
                let nr = pos.row + dr; let nc = pos.col + dc
                if nr >= 0 && nr < 8 && nc >= 0 && nc < 8 { if board[nr][nc] == nil || board[nr][nc]!.color != piece.color { moves.append((nr, nc)) } }
            }}
        }
        return moves
    }

    private func slidingMoves(from pos: (row: Int, col: Int), dirs: [(Int, Int)], color: Int) -> [(row: Int, col: Int)] {
        var moves: [(row: Int, col: Int)] = []
        for (dr, dc) in dirs {
            var nr = pos.row + dr; var nc = pos.col + dc
            while nr >= 0 && nr < 8 && nc >= 0 && nc < 8 {
                if let p = board[nr][nc] { if p.color != color { moves.append((nr, nc)) }; break }
                moves.append((nr, nc)); nr += dr; nc += dc
            }
        }
        return moves
    }

    private func pieceValue(_ type: ChessPiece.PieceType) -> Int {
        switch type { case .pawn: return 10; case .knight, .bishop: return 30; case .rook: return 50; case .queen: return 90; case .king: return 900 }
    }

    func finalReward() -> GameReward {
        let won = winner == 1
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let coins = baseCoinReward + (won ? winCoinBonus : 0)
        let gems = won && moveCount < 30 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: coins, gems: gems, badgeUnlocked: won ? "Chess Strategist" : nil)
    }
}
