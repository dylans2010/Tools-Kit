import SwiftUI

struct RouletteRoyalView: View {
    @StateObject private var logic = RouletteRoyalLogic()
    @State private var winningNumber = 0
    @State private var betAmount = 50
    @State private var selectedNumber: Int?
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Roulette Royal", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack {
                    Text("Roulette Royal").font(.title.bold()).foregroundColor(.white)
                    Text("Selected: \(selectedNumber?.description ?? "None")").foregroundColor(.secondary)

                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                            ForEach(0...36, id: \.self) { n in
                                Button("\(n)") { selectedNumber = n }
                                    .frame(height: 44)
                                    .background(selectedNumber == n ? Color.yellow : Color.green.opacity(0.3))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                    }

                    Button("SPIN") { spin() }
                        .disabled(selectedNumber == nil)
                        .buttonStyle(.borderedProminent)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: winningNumber == selectedNumber, score: winningNumber == selectedNumber ? betAmount * 35 : 0, streakMultiplier: 1.0)) {
                    gameState = .lobby
                }
            }
        }
    }

    private func spin() {
        winningNumber = Int.random(in: 0...36)
        gameState = .results
    }
}
