import Foundation

struct Bubble: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let size: Double
    let color: Int
    var popped: Bool = false
    var isGolden: Bool = false
    var isBomb: Bool = false
}

final class BubblePopFrenzyLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "bubble_pop_frenzy"
    let baseXPReward = 30
    let winXPBonus = 0
    let baseCoinReward = 15
    let winCoinBonus = 0

    @Published var bubbles: [Bubble] = []
    @Published var score = 0
    @Published var timeRemaining: Double = 30
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var combo = 0
    @Published var bestCombo = 0
    @Published var lastPoppedColor = -1
    @Published var difficulty = 0
    @Published var totalPopped = 0
    @Published var goldenPopped = 0
    @Published var bombsAvoided = 0
    @Published var bonusTimeEarned: Double = 0

    private var timer: Timer?
    private var spawnTimer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        bubbles = []; score = 0; gameOver = false; combo = 0; bestCombo = 0
        lastPoppedColor = -1; totalPopped = 0; goldenPopped = 0; bombsAvoided = 0; bonusTimeEarned = 0
        timeRemaining = Double(30 + difficulty * 10)
        phase = .playing; startTimers()
    }

    private func startTimers() {
        timer?.invalidate(); spawnTimer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 { self.endGame() }
        }
        let spawnRate = max(0.2, 0.5 - Double(difficulty) * 0.1)
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnRate, repeats: true) { [weak self] _ in
            guard let self = self, !self.gameOver else { return }
            self.spawnBubble()
        }
    }

    private func spawnBubble() {
        let isGolden = Double.random(in: 0...1) < 0.08
        let isBomb = difficulty >= 1 && Double.random(in: 0...1) < (0.05 + Double(difficulty) * 0.03)
        let b = Bubble(x: Double.random(in: 0.1...0.9), y: Double.random(in: 0.1...0.9),
                       size: Double.random(in: 30...60), color: Int.random(in: 0...4),
                       isGolden: isGolden, isBomb: isBomb)
        bubbles.append(b)
        if bubbles.count > 25 { bubbles.removeFirst() }
    }

    func popBubble(_ id: UUID) {
        guard let idx = bubbles.firstIndex(where: { $0.id == id && !$0.popped }) else { return }

        if bubbles[idx].isBomb {
            score = max(0, score - 50)
            combo = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.3)
            timeRemaining = max(0, timeRemaining - 3)
            bubbles[idx].popped = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.bubbles.removeAll { $0.id == id } }
            return
        }

        bubbles[idx].popped = true
        totalPopped += 1
        let bubble = bubbles[idx]

        if bubble.isGolden {
            goldenPopped += 1
            score += 100
            timeRemaining += 3
            bonusTimeEarned += 3
        }

        if bubble.color == lastPoppedColor { combo += 1 } else { combo = 1 }
        bestCombo = max(bestCombo, combo)
        lastPoppedColor = bubble.color
        let sizeBonus = Int(100.0 / bubble.size * 10)
        let comboMultiplier = min(combo, 8)
        score += sizeBonus * comboMultiplier

        if combo >= 5 {
            let bonusTime = Double(combo - 4) * 0.5
            timeRemaining += bonusTime
            bonusTimeEarned += bonusTime
        }

        streakMultiplier = min(3.0, 1.0 + Double(combo) * 0.1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.bubbles.removeAll { $0.id == id }
        }
    }

    private func endGame() {
        timer?.invalidate(); spawnTimer?.invalidate(); gameOver = true; phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 20)
        let diffBonus = difficulty * 10
        var badge: String?
        if score >= 500 { badge = "Bubble Buster" }
        if bestCombo >= 10 { badge = badge ?? "Combo King" }
        if goldenPopped >= 5 { badge = badge ?? "Golden Touch" }
        if totalPopped >= 100 { badge = badge ?? "Pop Master" }
        let gems = score >= 1500 && difficulty >= 1 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }

    deinit { timer?.invalidate(); spawnTimer?.invalidate() }
}
