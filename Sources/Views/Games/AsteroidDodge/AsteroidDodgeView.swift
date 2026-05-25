import SwiftUI

struct AsteroidDodgeView: View {
    @StateObject private var logic = AsteroidDodgeLogic()
    @State private var timeSurvived = 0
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Asteroid Dodge", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack {
                    Text("Survived: \(timeSurvived)s").font(.title).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "airplane").font(.largeTitle).foregroundColor(.white)
                    Spacer()
                    Button("Crash") { gameState = .results }
                }
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                        if gameState == .playing { timeSurvived += 1 } else { timer.invalidate() }
                    }
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: timeSurvived, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }
}
