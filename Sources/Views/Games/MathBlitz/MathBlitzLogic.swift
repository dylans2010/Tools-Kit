import Foundation

final class MathBlitzLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "math_blitz"
    let baseXPReward = 10
    let winXPBonus = 0
    let baseCoinReward = 5
    let winCoinBonus = 0

    @Published var question = ""
    @Published var answer = 0
    @Published var options: [Int] = []
    @Published var correctCount = 0
    @Published var totalCount = 0
    @Published var timeRemaining: Double = 60
    @Published var score = 0
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var lastCorrect: Bool?
    @Published var difficulty = 0
    @Published var consecutiveCorrect = 0
    @Published var bestConsecutive = 0
    @Published var bonusTimeEarned: Double = 0

    private var timer: Timer?
    private var playerLevel: Int { GamesPersistenceManager.shared.load().level }

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        correctCount = 0; totalCount = 0; score = 0
        timeRemaining = Double(60 + difficulty * 10)
        gameOver = false; consecutiveCorrect = 0; bestConsecutive = 0; bonusTimeEarned = 0
        phase = .playing; generateQuestion(); startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 { self.endGame() }
        }
    }

    func generateQuestion() {
        let lvl = playerLevel + difficulty
        if lvl <= 5 {
            let a = Int.random(in: 1...50)
            let b = Int.random(in: 1...50)
            if Bool.random() { question = "\(a) + \(b)"; answer = a + b }
            else { question = "\(a) - \(b)"; answer = a - b }
        } else if lvl <= 10 {
            if Bool.random() {
                let a = Int.random(in: 2...12); let b = Int.random(in: 2...12)
                question = "\(a) \u{00D7} \(b)"; answer = a * b
            } else {
                let b = Int.random(in: 2...12); let r = Int.random(in: 1...12)
                question = "\(b * r) \u{00F7} \(b)"; answer = r
            }
        } else {
            let a = Int.random(in: 1...50); let b = Int.random(in: 1...50)
            switch Int.random(in: 0...3) {
            case 0: question = "\(a) + \(b)"; answer = a + b
            case 1: question = "\(a) - \(b)"; answer = a - b
            case 2: let m1 = Int.random(in: 2...15); let m2 = Int.random(in: 2...15); question = "\(m1) \u{00D7} \(m2)"; answer = m1 * m2
            default: let d = Int.random(in: 2...12); let r = Int.random(in: 1...15); question = "\(d * r) \u{00F7} \(d)"; answer = r
            }
        }

        if difficulty >= 2 && Bool.random() {
            let a = Int.random(in: 2...10); let b = Int.random(in: 1...20); let c = Int.random(in: 1...10)
            if Bool.random() { question = "\(a) \u{00D7} \(b) + \(c)"; answer = a * b + c }
            else { question = "\(a) \u{00D7} \(b) - \(c)"; answer = a * b - c }
        }

        generateOptions()
    }

    private func generateOptions() {
        var opts = Set<Int>([answer])
        while opts.count < 4 {
            let offset = Int.random(in: 1...max(10, abs(answer / 4) + 1)) * (Bool.random() ? 1 : -1)
            opts.insert(answer + offset)
        }
        options = Array(opts).shuffled()
    }

    func selectAnswer(_ value: Int) {
        totalCount += 1
        if value == answer {
            correctCount += 1
            consecutiveCorrect += 1
            bestConsecutive = max(bestConsecutive, consecutiveCorrect)
            let comboBonus = min(consecutiveCorrect, 10)
            score += 10 * comboBonus
            streakMultiplier = min(3.0, streakMultiplier + 0.05 * Double(comboBonus))
            lastCorrect = true
            if consecutiveCorrect >= 5 && consecutiveCorrect % 5 == 0 {
                let bonusTime = Double(consecutiveCorrect / 5) * 3.0
                timeRemaining += bonusTime
                bonusTimeEarned += bonusTime
            }
        } else {
            consecutiveCorrect = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.1)
            lastCorrect = false
        }
        generateQuestion()
    }

    private func endGame() { timer?.invalidate(); gameOver = true; phase = .results }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward * correctCount) * streakMultiplier)
        let coins = baseCoinReward * correctCount
        let diffBonus = difficulty * 10
        var badge: String?
        if correctCount >= 30 { badge = "Math Wizard" }
        if bestConsecutive >= 20 { badge = badge ?? "Math Streak" }
        if correctCount >= 50 { badge = badge ?? "Math Genius" }
        let accuracy = totalCount > 0 ? Double(correctCount) / Double(totalCount) : 0
        if accuracy >= 0.95 && totalCount >= 20 { badge = badge ?? "Perfect Calculator" }
        let gems = correctCount >= 40 && difficulty >= 1 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: coins, gems: gems, badgeUnlocked: badge)
    }

    deinit { timer?.invalidate() }
}
