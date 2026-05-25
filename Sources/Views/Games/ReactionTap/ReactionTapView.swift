import SwiftUI

struct ReactionTapView: View {
    @StateObject private var logic = ReactionTapLogic()
    @State private var reactionTime = 0
    @State private var startTime: Date?
    @State private var showTarget = false
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Reaction Tap", gameID: logic.gameIdentifier) { wait() }
            case .playing:
                VStack {
                    if showTarget {
                        Circle().fill(Color.green).frame(width: 200, height: 200)
                            .onTapGesture { tap() }
                    } else {
                        Text("Wait for Green...").foregroundColor(.secondary)
                    }
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: reactionTime, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func wait() {
        gameState = .playing
        showTarget = false
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.5...3.0)) {
            showTarget = true
            startTime = Date()
        }
    }

    private func tap() {
        if let start = startTime {
            reactionTime = Int(Date().timeIntervalSince(start) * 1000)
            gameState = .results
        }
    }
}
