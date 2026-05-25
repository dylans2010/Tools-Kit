import SwiftUI

struct SequenceRecallView: View {
    @StateObject private var logic = SequenceRecallLogic()
    @State private var gameState: GameState = .lobby
    @State private var round = 1

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Sequence Recall", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack(spacing: 20) {
                    Text("Round \(round)").font(.title).foregroundColor(.white)
                    HStack {
                        ForEach(0..<4) { i in
                            Circle().fill(Color.blue).frame(width: 60, height: 60)
                                .onTapGesture { round += 1 }
                        }
                    }
                    Button("I Forgot") { gameState = .results }
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: round, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }
}
