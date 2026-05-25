import SwiftUI

struct DiceRollFortuneView: View {
    @StateObject private var logic = DiceRollFortuneLogic()
    @State private var dice = [1, 1]
    @State private var bet = 20
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Dice Roll Fortune", gameID: logic.gameIdentifier) { gameState = .playing }
            case .playing:
                VStack(spacing: 40) {
                    HStack(spacing: 20) {
                        ForEach(0..<dice.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 12).fill(Color.white).frame(width: 80, height: 80)
                                .overlay(Image(systemName: "die.face.\(dice[index]).fill").font(.system(size: 40)).foregroundColor(.black))
                        }
                    }
                    Button("ROLL DICE") { roll() }
                        .buttonStyle(.borderedProminent)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: dice[0] == dice[1], score: dice[0] == dice[1] ? bet * 5 : 0, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func roll() {
        dice = [Int.random(in: 1...6), Int.random(in: 1...6)]
        gameState = .results
    }
}
