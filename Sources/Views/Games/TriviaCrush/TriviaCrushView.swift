import SwiftUI

struct TriviaCrushView: View {
    @StateObject private var logic = TriviaCrushLogic()
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var gameState: GameState = .lobby

    enum GameState { case lobby, playing, results }

    var questions: [TriviaQuestion] { TriviaCrushQuestionBank.questions }

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            switch gameState {
            case .lobby:
                LobbyView(title: "Trivia Crush", gameID: logic.gameIdentifier) {
                    currentQuestionIndex = 0
                    score = 0
                    gameState = .playing
                }
            case .playing:
                VStack(spacing: 24) {
                    Text("Question \(currentQuestionIndex + 1)/\(questions.count)").foregroundColor(.secondary)
                    Text(questions[currentQuestionIndex].question).font(.title3.bold()).foregroundColor(.white).multilineTextAlignment(.center).padding()

                    ForEach(0..<4) { i in
                        Button {
                            answer(i)
                        } label: {
                            Text(questions[currentQuestionIndex].answers[i])
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            case .results:
                ResultsView(reward: logic.calculateFinalReward(won: score > 0, score: score, streakMultiplier: 1.0)) { gameState = .lobby }
            }
        }
    }

    private func answer(_ index: Int) {
        if index == questions[currentQuestionIndex].correctIndex { score += 1 }
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
        } else {
            gameState = .results
        }
    }
}
