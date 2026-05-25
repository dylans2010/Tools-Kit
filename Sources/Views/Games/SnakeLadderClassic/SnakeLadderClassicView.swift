import SwiftUI

struct SnakeLadderClassicView: View {
    @StateObject private var logic = SnakeLadderClassicLogic()
    @State private var playerPos = 1
    @State private var aiPos = 1
    @State private var dice = 1
    @State private var gameState: GameState = .lobby
    @State private var isPlayerTurn = true
    @State private var message = "Your Turn"

    enum GameState { case lobby, playing, results }

    let boardSize = 10
    let snakes = [16: 6, 47: 26, 49: 11, 56: 53, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 98: 78]
    let ladders = [1: 38, 4: 14, 9: 31, 21: 42, 28: 84, 36: 44, 51: 67, 71: 91, 80: 100]

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Snake & Ladder", gameID: logic.gameIdentifier) {
                    playerPos = 1; aiPos = 1; isPlayerTurn = true; message = "Your Turn"; gameState = .playing
                }
            case .playing:
                VStack(spacing: 20) {
                    Text(message).foregroundColor(.gold)
                    HStack {
                        VStack { Text("YOU").font(.caption); Text("\(playerPos)").bold() }
                        Spacer()
                        Image(systemName: "die.face.\(dice).fill").font(.largeTitle)
                        Spacer()
                        VStack { Text("AI").font(.caption); Text("\(aiPos)").bold() }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                    if isPlayerTurn {
                        Button("ROLL DICE") { roll() }.buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: playerPos >= 100, score: 0, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func roll() {
        dice = Int.random(in: 1...6)
        playerPos = move(from: playerPos, by: dice)
        if playerPos >= 100 { gameState = .results; return }

        isPlayerTurn = false
        message = "AI Rolling..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dice = Int.random(in: 1...6)
            aiPos = move(from: aiPos, by: dice)
            if aiPos >= 100 { gameState = .results; return }
            isPlayerTurn = true
            message = "Your Turn"
        }
    }

    private func move(from pos: Int, by d: Int) -> Int {
        var newPos = pos + d
        if newPos > 100 { newPos = 100 - (newPos - 100) }
        if let jump = ladders[newPos] { return jump }
        if let drop = snakes[newPos] { return drop }
        return newPos
    }
}
