import SwiftUI

struct ScratchAndWinView: View {
    @StateObject private var logic = ScratchAndWinLogic()
    @State private var grid = Array(repeating: false, count: 9)
    @State private var symbols = (0..<9).map { _ in ["🍒", "🔔", "⭐"].randomElement()! }
    @State private var gameState: GameState = .lobby
    @State private var cost = 50

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Scratch & Win", gameID: logic.gameIdentifier) { startNew() }
            case .playing:
                VStack {
                    Text("Scratch to Reveal").foregroundColor(.white)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                        ForEach(0..<9) { i in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(Color.gray)
                                    .opacity(grid[i] ? 0 : 1)
                                Text(symbols[i]).font(.title)
                            }
                            .frame(height: 80)
                            .onTapGesture { grid[i] = true; check() }
                        }
                    }
                }
                .padding()
            case .results:
                let win = Set(symbols).count < 3 // Simplified win check
                ResultsView(reward: logic.calculateFinalReward(won: win, score: win ? 200 : 0, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func startNew() {
        try? CurrencyLedger.shared.spendCoins(cost)
        grid = Array(repeating: false, count: 9)
        symbols = (0..<9).map { _ in ["🍒", "🔔", "⭐"].randomElement()! }
        gameState = .playing
    }

    private func check() {
        if grid.allSatisfy({ $0 }) { gameState = .results }
    }
}
