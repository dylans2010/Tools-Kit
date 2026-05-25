import SwiftUI

struct MathBlitzView: View {
    @StateObject private var logic = MathBlitzLogic()
    @State private var score = 0
    @State private var problem = ""
    @State private var answer = 0
    @State private var userInput = ""
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Math Blitz", gameID: logic.gameIdentifier) { nextProblem() }
            case .playing:
                VStack(spacing: 30) {
                    Text("Solve:").foregroundColor(.secondary)
                    Text(problem).font(.system(size: 60, weight: .black, design: .rounded)).foregroundColor(.white)
                    TextField("?", text: $userInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 80)
                        .onSubmit { check() }
                    Button("SUBMIT") { check() }
                        .buttonStyle(.borderedProminent)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: score, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func nextProblem() {
        let a = Int.random(in: 1...10)
        let b = Int.random(in: 1...10)
        problem = "\(a) + \(b)"
        answer = a + b
        userInput = ""
        gameState = .playing
    }

    private func check() {
        if Int(userInput) == answer {
            score += 1
            if score >= 10 { gameState = .results } else { nextProblem() }
        }
    }
}
