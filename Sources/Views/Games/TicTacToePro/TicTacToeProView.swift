import SwiftUI

struct TicTacToeProView: View {
    @StateObject private var logic = TicTacToeProLogic()
    @State private var board = Array(repeating: "", count: 9)
    @State private var gameState: GameState = .lobby
    @State private var playerTurn = true
    @State private var resultMessage = ""

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "TicTacToe Pro", gameID: logic.gameIdentifier) {
                    board = Array(repeating: "", count: 9)
                    playerTurn = true
                    resultMessage = ""
                    gameState = .playing
                }
            case .playing:
                VStack(spacing: 20) {
                    Text(playerTurn ? "Your Turn (X)" : "AI Thinking... (O)")
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(100), spacing: 10), count: 3), spacing: 10) {
                        ForEach(0..<9) { i in
                            Button {
                                if board[i] == "" && playerTurn {
                                    makeMove(at: i)
                                }
                            } label: {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(board[i])
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(board[i] == "X" ? .cyan : .pink)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: resultMessage == "YOU WIN!", score: 0, streakMultiplier: 1.0)) {
                    gameState = .lobby
                }
            }
        }
    }

    private func makeMove(at index: Int) {
        board[index] = "X"
        if checkWin(for: "X") {
            resultMessage = "YOU WIN!"
            endGame()
        } else if board.allSatisfy({ !$0.isEmpty }) {
            resultMessage = "DRAW"
            endGame()
        } else {
            playerTurn = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                aiMove()
            }
        }
    }

    private func aiMove() {
        let move = logic.bestMove(board: board)
        if move != -1 {
            board[move] = "O"
            if checkWin(for: "O") {
                resultMessage = "AI WINS"
                endGame()
            } else if board.allSatisfy({ !$0.isEmpty }) {
                resultMessage = "DRAW"
                endGame()
            } else {
                playerTurn = true
            }
        }
    }

    private func checkWin(for p: String) -> Bool {
        let wins: [[Int]] = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]
        return wins.contains { $0.allSatisfy { board[$0] == p } }
    }

    private func endGame() {
        gameState = .results
    }
}
