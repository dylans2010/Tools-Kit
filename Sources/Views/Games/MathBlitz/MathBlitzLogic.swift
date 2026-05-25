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

    private var timer: Timer?
    private var playerLevel: Int { GamesPersistenceManager.shared.load().level }

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        correctCount = 0; totalCount = 0; score = 0; timeRemaining = 60
        gameOver = false; phase = .playing; generateQuestion(); startTimer()
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
        let lvl = playerLevel
        if lvl <= 5 {
            let a = Int.random(in: 1...50)
            let b = Int.random(in: 1...50)
            if Bool.random() { question = "\(a) + \(b)"; answer = a + b }
            else { question = "\(a) - \(b)"; answer = a - b }
        } else if lvl <= 10 {
            if Bool.random() {
                let a = Int.random(in: 2...12); let b = Int.random(in: 2...12)
                question = "\(a) × \(b)"; answer = a * b
            } else {
                let b = Int.random(in: 2...12); let r = Int.random(in: 1...12)
                question = "\(b * r) ÷ \(b)"; answer = r
            }
        } else {
            let a = Int.random(in: 1...50); let b = Int.random(in: 1...50)
            switch Int.random(in: 0...3) {
            case 0: question = "\(a) + \(b)"; answer = a + b
            case 1: question = "\(a) - \(b)"; answer = a - b
            case 2: let m1 = Int.random(in: 2...12); let m2 = Int.random(in: 2...12); question = "\(m1) × \(m2)"; answer = m1 * m2
            default: let d = Int.random(in: 2...12); let r = Int.random(in: 1...12); question = "\(d * r) ÷ \(d)"; answer = r
            }
        }
        generateOptions()
    }

    private func generateOptions() {
        var opts = Set<Int>([answer])
        while opts.count < 4 {
            let offset = Int.random(in: 1...10) * (Bool.random() ? 1 : -1)
            opts.insert(answer + offset)
        }
        options = Array(opts).shuffled()
    }

    func selectAnswer(_ value: Int) {
        totalCount += 1
        if value == answer {
            correctCount += 1; score += 10
            streakMultiplier = min(3.0, streakMultiplier + 0.1); lastCorrect = true
        } else { streakMultiplier = 1.0; lastCorrect = false }
        generateQuestion()
    }

    private func endGame() { timer?.invalidate(); gameOver = true; phase = .results }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward * correctCount) * streakMultiplier)
        let coins = baseCoinReward * correctCount
        return GameReward(xp: max(1, xp), coins: coins, gems: 0, badgeUnlocked: correctCount >= 30 ? "Math Wizard" : nil)
    }

    deinit { timer?.invalidate() }
}
