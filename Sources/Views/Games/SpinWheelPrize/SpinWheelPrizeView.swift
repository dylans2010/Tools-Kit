import SwiftUI

struct SpinWheelPrizeView: View {
    @StateObject private var logic = SpinWheelPrizeLogic()
    @State private var rotation = 0.0
    @State private var isSpinning = false
    @State private var winAmount = 0
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Spin Wheel Prize", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack(spacing: 40) {
                    Text("Prize Wheel").font(.title.bold()).foregroundColor(.white)

                    ZStack {
                        SpinningWheelView(rotation: rotation)
                            .frame(width: 300, height: 300)
                        Image(systemName: "arrowtriangle.down.fill").foregroundColor(.red).offset(y: -160)
                    }

                    Button("SPIN (100 💰)") { spin() }
                        .disabled(isSpinning)
                        .buttonStyle(.borderedProminent)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: winAmount, streakMultiplier: 1.0)) {
                    gameState = .lobby
                }
            }
        }
    }

    private func spin() {
        isSpinning = true
        let extraRotation = Double.random(in: 1080...3600)
        rotation += extraRotation

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isSpinning = false
            winAmount = [100, 200, 500, 1000, 5000].randomElement()!
            gameState = .results
        }
    }
}
