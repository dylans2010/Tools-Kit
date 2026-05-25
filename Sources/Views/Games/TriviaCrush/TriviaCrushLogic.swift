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
    @Published var timerRemaining: Int = 30
    @Published var bestConsecutiveCorrect: Int = 0
    @Published var consecutiveCorrect = 0
    @Published var bestConsecutive = 0
    @Published var difficulty = 0
    @Published var timePerQuestion: Double = 0
    @Published var timeRemaining: Double = 30
    @Published var usedFiftyFifty = false
    @Published var fiftyFiftyAvailable = true
    @Published var eliminatedOptions: Set<Int> = []
    @Published var questionCount = 10

    private var timer: Timer?

    enum GamePhase { case lobby, playing, results }

    var currentQuestion: TriviaQuestion? {
        currentIndex < questions.count ? questions[currentIndex] : nil
    }

    func startGame(category: String = "All", difficulty: Int = 0) {
        self.difficulty = difficulty
        questionCount = 10 + difficulty * 5
        questions = TriviaCrushQuestionBank.questions(forCategory: category, count: questionCount)
        currentIndex = 0; correctAnswers = 0; score = 0; selectedAnswer = nil
        gameOver = false; consecutiveCorrect = 0; bestConsecutive = 0
        usedFiftyFifty = false; fiftyFiftyAvailable = true; eliminatedOptions = []
        timePerQuestion = difficulty == 0 ? 30 : (difficulty == 1 ? 20 : 12)
        timeRemaining = timePerQuestion
        phase = .playing
        startQuestionTimer()
    }

    private func startQuestionTimer() {
        timer?.invalidate()
        guard difficulty >= 1 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 {
                self.timer?.invalidate()
                self.handleTimeout()
            }
        }
    }

    private func handleTimeout() {
        selectedAnswer = -1
        consecutiveCorrect = 0
        streakMultiplier = max(1.0, streakMultiplier - 0.15)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.nextQuestion()
        }
    }

    func selectAnswer(_ index: Int) {
        guard selectedAnswer == nil, let q = currentQuestion else { return }
        timer?.invalidate()
        selectedAnswer = index
        if index == q.correctIndex {
            correctAnswers += 1
            consecutiveCorrect += 1
            bestConsecutive = max(bestConsecutive, consecutiveCorrect)
            let basePoints = 100
            let comboBonus = min(consecutiveCorrect, 10) * 25
            let speedBonus = difficulty >= 1 ? Int(timeRemaining) * 5 : 0
            score += basePoints + comboBonus + speedBonus
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else {
            consecutiveCorrect = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.nextQuestion()
        }
    }

    func useFiftyFifty() {
        guard fiftyFiftyAvailable, let q = currentQuestion, selectedAnswer == nil else { return }
        fiftyFiftyAvailable = false
        usedFiftyFifty = true
        var wrongIndices = (0..<q.options.count).filter { $0 != q.correctIndex }
        wrongIndices.shuffle()
        let toEliminate = wrongIndices.prefix(2)
        eliminatedOptions = Set(toEliminate)
    }

    private func nextQuestion() {
        selectedAnswer = nil
        eliminatedOptions = []
        currentIndex += 1
        if currentIndex >= questions.count { gameOver = true; timer?.invalidate(); phase = .results }
        else {
            timeRemaining = timePerQuestion
            if difficulty >= 1 { startQuestionTimer() }
        }
    }

    func finalReward() -> GameReward {
        let accuracy = questions.isEmpty ? 0 : Double(correctAnswers) / Double(questions.count)
        let xp = Int(Double(baseXPReward + correctAnswers * 8) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 20)
        let diffBonus = difficulty * 20
        var badge: String?
        if correctAnswers == questions.count { badge = "Trivia Genius" }
        if bestConsecutive >= 10 { badge = badge ?? "Trivia Streak" }
        if accuracy >= 0.9 && difficulty >= 2 { badge = badge ?? "Quiz Master" }
        let gems = correctAnswers == questions.count && difficulty >= 1 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }

    deinit { timer?.invalidate() }
}
