import SwiftUI

struct WarZoneStrikeView: View {
    @StateObject private var logic = WarZoneStrikeLogic()
    @State private var gameState: GameState = .lobby
    @State private var score = 0

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "WarZone Strike", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack {
                    Text("Score: \(score)").font(.title).foregroundColor(.white)
                    Spacer()
                    HStack {
                        ForEach(0..<3) { _ in
                            Capsule().fill(Color.gray.opacity(0.3)).frame(width: 60, height: 300)
                                .onTapGesture { score += 10 }
                        }
                    }
                    Spacer()
                    Button("End Mission") { gameState = .results }
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: score, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }
}
