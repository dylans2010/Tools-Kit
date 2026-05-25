import Foundation

final class TriviaCrushLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "trivia_crush"
    let baseXPReward = 60
    let winXPBonus = 0
    let baseCoinReward = 30
    let winCoinBonus = 0

    @Published var questions: [TriviaQuestion] = []
    @Published var currentIndex = 0
    @Published var selectedAnswer: Int?
    @Published var correctAnswers = 0
    @Published var score = 0
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0

    enum GamePhase { case lobby, playing, results }

    var currentQuestion: TriviaQuestion? {
        currentIndex < questions.count ? questions[currentIndex] : nil
    }

    func startGame(category: String = "All") {
        questions = TriviaCrushQuestionBank.questions(forCategory: category, count: 10)
        currentIndex = 0; correctAnswers = 0; score = 0; selectedAnswer = nil
        gameOver = false; phase = .playing
    }

    func selectAnswer(_ index: Int) {
        guard selectedAnswer == nil, let q = currentQuestion else { return }
        selectedAnswer = index
        if index == q.correctIndex {
            correctAnswers += 1
            score += 100
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else {
            streakMultiplier = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.nextQuestion()
        }
    }

    private func nextQuestion() {
        selectedAnswer = nil
        currentIndex += 1
        if currentIndex >= questions.count { gameOver = true; phase = .results }
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + correctAnswers * 8) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 20)
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: 0, badgeUnlocked: correctAnswers == 10 ? "Trivia Genius" : nil)
    }
}
