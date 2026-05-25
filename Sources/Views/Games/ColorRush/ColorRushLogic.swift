import Foundation

final class ColorRushLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "color_rush"
    let baseXPReward = 25
    let winXPBonus = 0
    let baseCoinReward = 12
    let winCoinBonus = 0

    let colorNames = ["Red", "Blue", "Green", "Yellow", "Purple", "Orange"]
    let colorIndices = [0, 1, 2, 3, 4, 5]

    @Published var displayedWord = ""
    @Published var displayedColorIndex = 0
    @Published var correctColorIndex = 0
    @Published var score = 0
    @Published var timeRemaining: Double = 30
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var difficulty = 0
    @Published var consecutiveCorrect = 0
    @Published var bestConsecutive = 0
    @Published var totalAnswered = 0
    @Published var correctAnswers = 0
    @Published var bonusTimeEarned: Double = 0
    @Published var mode = 0

    private var timer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int = 0, mode: Int = 0) {
        self.difficulty = difficulty
        self.mode = mode
        score = 0; gameOver = false; consecutiveCorrect = 0; bestConsecutive = 0
        totalAnswered = 0; correctAnswers = 0; bonusTimeEarned = 0
        timeRemaining = Double(30 + difficulty * 10)
        phase = .playing; generateRound(); startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 { self.endGame() }
        }
    }

    func generateRound() {
        let wordIdx = Int.random(in: 0..<colorNames.count)
        displayedWord = colorNames[wordIdx]
        displayedColorIndex = Int.random(in: 0..<colorNames.count)
        correctColorIndex = mode == 0 ? displayedColorIndex : wordIdx
    }

    func selectColor(_ index: Int) {
        totalAnswered += 1
        if index == correctColorIndex {
            correctAnswers += 1
            consecutiveCorrect += 1
            bestConsecutive = max(bestConsecutive, consecutiveCorrect)
            let comboBonus = min(consecutiveCorrect, 10) * 2
            score += 10 + comboBonus
            streakMultiplier = min(3.0, streakMultiplier + 0.08)
            if consecutiveCorrect >= 5 && consecutiveCorrect % 5 == 0 {
                let bonus = 2.0
                timeRemaining += bonus
                bonusTimeEarned += bonus
            }
        } else {
            consecutiveCorrect = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.15)
            if difficulty >= 1 { timeRemaining = max(0, timeRemaining - 2) }
        }
        generateRound()
    }

    private func endGame() { timer?.invalidate(); gameOver = true; phase = .results }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward) * streakMultiplier) + (score / 5)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 10)
        let diffBonus = difficulty * 10
        let accuracy = totalAnswered > 0 ? Double(correctAnswers) / Double(totalAnswered) : 0
        var badge: String?
        if score >= 200 { badge = "Color Expert" }
        if bestConsecutive >= 20 { badge = badge ?? "Color Streak" }
        if accuracy >= 0.95 && totalAnswered >= 30 { badge = badge ?? "Perfect Vision" }
        if score >= 500 { badge = badge ?? "Color Master" }
        let gems = score >= 400 && difficulty >= 1 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }

    deinit { timer?.invalidate() }
}
