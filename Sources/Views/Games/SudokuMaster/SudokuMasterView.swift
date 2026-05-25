import SwiftUI

struct SudokuMasterView: View {
    @StateObject private var logic = SudokuMasterLogic()
    @State private var grid = SudokuGenerator.generate()
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Sudoku Master", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack {
                    Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                        ForEach(0..<9) { r in
                            GridRow {
                                ForEach(0..<9) { c in
                                    ZStack {
                                        Rectangle().fill(Color.white.opacity(0.1)).frame(width: 35, height: 35)
                                        if grid[r][c] != 0 {
                                            Text("\(grid[r][c])").foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .background(Color.white.opacity(0.2))
                    .padding()
                    Button("FINISH") { gameState = .results }
                        .buttonStyle(.borderedProminent)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: 1000, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }
}
