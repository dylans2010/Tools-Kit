import SwiftUI

struct WordStormView: View {
    @StateObject private var logic = WordStormLogic()
    @State private var currentWord = ""
    @State private var shuffledWord = ""
    @State private var userInput = ""
    @State private var score = 0
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Word Storm", gameID: logic.gameIdentifier) { nextWord() }
            case .playing:
                VStack(spacing: 30) {
                    Text("Unscramble:").foregroundColor(.secondary)
                    Text(shuffledWord).font(.system(size: 44, weight: .black, design: .monospaced)).foregroundColor(.white)
                    TextField("Your answer", text: $userInput)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 40)
                        .onSubmit { check() }
                    Button("SUBMIT") { check() }
                        .buttonStyle(.borderedProminent)
                }
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: true, score: score, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func nextWord() {
        currentWord = WordStormDictionary.words.randomElement()!
        shuffledWord = String(currentWord.shuffled())
        userInput = ""
        gameState = .playing
    }

    private func check() {
        if userInput.uppercased() == currentWord {
            score += 1
            if score >= 5 { gameState = .results } else { nextWord() }
        }
    }
}
