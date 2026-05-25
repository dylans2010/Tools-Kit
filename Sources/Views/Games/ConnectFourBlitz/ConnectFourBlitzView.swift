import SwiftUI

struct ConnectFourBlitzView: View {
    @StateObject private var logic = ConnectFourBlitzLogic()
    @State private var board = Array(repeating: Array(repeating: 0, count: 7), count: 6)
    @State private var gameState: GameState = .lobby
    @State private var playerTurn = true
    @State private var message = "Your Turn"

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Connect Four Blitz", gameID: logic.gameIdentifier) {
                    board = Array(repeating: Array(repeating: 0, count: 7), count: 6)
                    playerTurn = true
                    message = "Your Turn"
                    gameState = .playing
                }
            case .playing:
                VStack(spacing: 20) {
                    Text(message).foregroundColor(.secondary)

                    VStack(spacing: 5) {
                        ForEach(0..<6) { r in
                            HStack(spacing: 5) {
                                ForEach(0..<7) { c in
                                    Circle()
                                        .fill(color(for: board[r][c]))
                                        .frame(width: 40, height: 40)
                                        .onTapGesture { if playerTurn { drop(at: c) } }
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.3).cornerRadius(10))
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: message == "YOU WIN!", score: 0, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func color(for val: Int) -> Color {
        val == 1 ? .red : (val == 2 ? .yellow : Color.white.opacity(0.1))
    }

    private func drop(at col: Int) {
        guard let r = (0..<6).reversed().first(where: { board[$0][col] == 0 }) else { return }
        board[r][col] = 1
        if logic.checkWin(board: board) { message = "YOU WIN!"; gameState = .results; return }

        playerTurn = false
        message = "AI Thinking..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            aiMove()
        }
    }

    private func aiMove() {
        let cols = (0..<7).shuffled()
        for c in cols {
            if let r = (0..<6).reversed().first(where: { board[$0][c] == 0 }) {
                board[r][c] = 2
                if logic.checkWin(board: board) { message = "AI WINS"; gameState = .results; return }
                playerTurn = true
                message = "Your Turn"
                return
            }
        }
    }
}
