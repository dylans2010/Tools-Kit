import SwiftUI

struct BattlefieldCommanderView: View {
    @StateObject private var logic = BattlefieldCommanderLogic()
    @State private var gameState: GameState = .lobby
    @State private var board = Array(repeating: Array(repeating: 0, count: 10), count: 10) // 0: empty, 1: player, 2: enemy

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()

            switch gameState {
            case .lobby:
                LobbyView(title: "Battlefield Commander", gameID: logic.gameIdentifier) {
                    start()
                }
            case .playing:
                VStack {
                    Text("Capture the flags").font(.headline).foregroundColor(.white)
                    Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                        ForEach(0..<10) { r in
                            GridRow {
                                ForEach(0..<10) { c in
                                    Rectangle()
                                        .fill(color(for: board[r][c]))
                                        .frame(width: 30, height: 30)
                                        .onTapGesture { tap(r, c) }
                                }
                            }
                        }
                    }
                    .background(Color.white.opacity(0.1))

                    Button("Capture Flag (Win)") { gameState = .results }
                        .padding(.top)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: 1500, streakMultiplier: 1.0)) {
                    gameState = .lobby
                }
            }
        }
    }

    private func color(for val: Int) -> Color {
        val == 1 ? .blue : (val == 2 ? .red : .green.opacity(0.2))
    }

    private func start() {
        board = Array(repeating: Array(repeating: 0, count: 10), count: 10)
        board[0][0] = 1; board[9][9] = 2
        gameState = .playing
    }

    private func tap(_ r: Int, _ c: Int) {
        if board[r][c] == 0 { board[r][c] = 1 }
    }
}
