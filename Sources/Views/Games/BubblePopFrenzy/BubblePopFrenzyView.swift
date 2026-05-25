import SwiftUI

struct BubblePopFrenzyView: View {
    @StateObject private var logic = BubblePopFrenzyLogic()
    @State private var score = 0
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Bubble Pop Frenzy", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack {
                    Text("Score: \(score)").font(.title).foregroundColor(.white)
                    Spacer()
                    ZStack {
                        ForEach(0..<5) { i in
                            Circle().fill(Color.blue.opacity(0.5)).frame(width: 60, height: 60)
                                .offset(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -200...200))
                                .onTapGesture { score += 10 }
                        }
                    }
                    Spacer()
                    Button("End Frenzy") { gameState = .results }
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: score, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }
}
