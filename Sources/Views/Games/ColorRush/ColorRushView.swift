import SwiftUI

struct ColorRushView: View {
    @StateObject private var logic = ColorRushLogic()
    @State private var score = 0
    @State private var currentColor = Color.red
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Color Rush", gameID: logic.gameIdentifier) { next() }
            case .playing:
                VStack(spacing: 40) {
                    Text("Score: \(score)").foregroundColor(.white)
                    Rectangle().fill(currentColor).frame(width: 100, height: 100)
                    HStack {
                        Button("Red") { tap(.red) }.tint(.red)
                        Button("Green") { tap(.green) }.tint(.green)
                        Button("Blue") { tap(.blue) }.tint(.blue)
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: score, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func next() {
        currentColor = [Color.red, Color.green, Color.blue].randomElement()!
        gameState = .playing
    }

    private func tap(_ color: Color) {
        if color == currentColor { score += 1; next() } else { gameState = .results }
    }
}
