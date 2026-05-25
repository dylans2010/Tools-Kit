import SwiftUI

struct ChessLiteView: View {
    @StateObject private var logic = ChessLiteLogic()
    @State private var gameState: GameState = .lobby
    @State private var board: [[ChessPieceModel?]] = []
    @State private var selected: (Int, Int)?

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Chess Lite", gameID: logic.gameIdentifier) { start() }
            case .playing:
                VStack {
                    Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                        ForEach(0..<8) { r in
                            GridRow {
                                ForEach(0..<8) { c in
                                    cellView(r, c)
                                }
                            }
                        }
                    }
                    .padding()
                    Button("FORFEIT") { gameState = .results }
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: false, score: 0, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func cellView(_ r: Int, _ c: Int) -> some View {
        ZStack {
            Rectangle().fill((r + c) % 2 == 0 ? Color.white.opacity(0.1) : Color.black.opacity(0.3))
            if let piece = board[r][c] {
                Image(systemName: icon(for: piece))
                    .foregroundColor(piece.isWhite ? .white : .gray)
                    .font(.title2)
            }
        }
        .frame(width: 40, height: 40)
        .overlay(Rectangle().stroke(selected?.0 == r && selected?.1 == c ? Color.yellow : Color.clear, lineWidth: 2))
        .onTapGesture { tap(r, c) }
    }

    private func icon(for piece: ChessPieceModel) -> String {
        switch piece.type {
        case .pawn: return "checkerboard.shield"
        case .rook: return "building.columns.fill"
        case .knight: return "figure.walk"
        case .bishop: return "cross.fill"
        case .queen: return "crown.fill"
        case .king: return "crown"
        }
    }

    private func start() {
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        // Set up simplified board
        for c in 0..<8 { board[1][c] = ChessPieceModel(type: .pawn, isWhite: false) }
        for c in 0..<8 { board[6][c] = ChessPieceModel(type: .pawn, isWhite: true) }
        board[0][0] = ChessPieceModel(type: .rook, isWhite: false); board[0][7] = ChessPieceModel(type: .rook, isWhite: false)
        board[7][0] = ChessPieceModel(type: .rook, isWhite: true); board[7][7] = ChessPieceModel(type: .rook, isWhite: true)
        gameState = .playing
    }

    private func tap(_ r: Int, _ c: Int) {
        if let s = selected {
            if logic.isValidMove(piece: board[s.0][s.1]!, from: s, to: (r, c), board: board) {
                board[r][c] = board[s.0][s.1]
                board[s.0][s.1] = nil
                selected = nil
            } else {
                selected = board[r][c]?.isWhite == true ? (r, c) : nil
            }
        } else if board[r][c]?.isWhite == true {
            selected = (r, c)
        }
    }
}
