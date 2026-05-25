import SwiftUI

struct CheckersArenaView: View {
    @StateObject private var logic = CheckersArenaLogic()
    @State private var gameState: GameState = .lobby
    @State private var board: [[Int]] = [] // 0: empty, 1: white, 2: red
    @State private var selected: (Int, Int)?
    @State private var playerTurn = true

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Checkers Arena", gameID: logic.gameIdentifier) { start() }
            case .playing:
                VStack {
                    Text(playerTurn ? "Your Turn" : "AI Thinking...").foregroundColor(.secondary)
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
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: 0, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func cellView(_ r: Int, _ c: Int) -> some View {
        ZStack {
            Rectangle().fill((r + c) % 2 == 0 ? Color.red.opacity(0.1) : Color.black.opacity(0.3))
            if board[r][c] != 0 {
                Circle()
                    .fill(board[r][c] == 1 ? Color.white : Color.red)
                    .padding(4)
                    .overlay(Circle().stroke(selected?.0 == r && selected?.1 == c ? Color.yellow : Color.clear, lineWidth: 2))
            }
        }
        .frame(width: 40, height: 40)
        .onTapGesture { tap(r, c) }
    }

    private func start() {
        board = Array(repeating: Array(repeating: 0, count: 8), count: 8)
        for r in 0..<3 { for c in 0..<8 { if (r + c) % 2 != 0 { board[r][c] = 2 } } }
        for r in 5..<8 { for c in 0..<8 { if (r + c) % 2 != 0 { board[r][c] = 1 } } }
        playerTurn = true
        gameState = .playing
    }

    private func tap(_ r: Int, _ c: Int) {
        guard playerTurn else { return }
        if board[r][c] == 1 { selected = (r, c) }
        else if let s = selected, board[r][c] == 0, (r + c) % 2 != 0 {
            if abs(r - s.0) == 1 && r < s.0 {
                board[r][c] = 1
                board[s.0][s.1] = 0
                selected = nil
                endTurn()
            }
        }
    }

    private func endTurn() {
        playerTurn = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            aiMove()
        }
    }

    private func aiMove() {
        // Simple AI: first valid move
        for r in 0..<7 {
            for c in 0..<8 {
                if board[r][c] == 2 {
                    let targets = [(r+1, c-1), (r+1, c+1)]
                    for t in targets {
                        if t.0 < 8, t.1 >= 0, t.1 < 8, board[t.0][t.1] == 0 {
                            board[t.0][t.1] = 2
                            board[r][c] = 0
                            playerTurn = true
                            return
                        }
                    }
                }
            }
        }
        playerTurn = true
    }
}
