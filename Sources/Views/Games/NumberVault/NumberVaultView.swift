import SwiftUI

struct NumberVaultView: View {
    @StateObject private var logic = NumberVaultLogic()
    @State private var gameState: GameState = .lobby
    @State private var correctAnswers = 0

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Number Vault", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack(spacing: 20) {
                    Text("Vault Security: \(correctAnswers)").foregroundColor(.white)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                        ForEach(0..<9) { i in
                            RoundedRectangle(cornerRadius: 8).fill(Color.orange).frame(height: 60)
                                .overlay(Text("\(Int.random(in: 1...99))").bold())
                                .onTapGesture { correctAnswers += 1 }
                        }
                    }
                    Button("Close Vault") { gameState = .results }
                }
                .padding()
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: correctAnswers, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }
}
