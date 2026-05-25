import Foundation

struct Bubble: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let size: Double
    let color: Int
    var popped: Bool = false
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
    @Published var lastPoppedColor = -1

    private var timer: Timer?
    private var spawnTimer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        bubbles = []; score = 0; timeRemaining = 30; gameOver = false; combo = 0; lastPoppedColor = -1
        phase = .playing; startTimers()
    }

    private func startTimers() {
        timer?.invalidate(); spawnTimer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 { self.endGame() }
        }
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, !self.gameOver else { return }
            self.spawnBubble()
        }
    }

    private func spawnBubble() {
        let b = Bubble(x: Double.random(in: 0.1...0.9), y: Double.random(in: 0.1...0.9),
                       size: Double.random(in: 30...60), color: Int.random(in: 0...4))
        bubbles.append(b)
        if bubbles.count > 20 { bubbles.removeFirst() }
    }

    func popBubble(_ id: UUID) {
        guard let idx = bubbles.firstIndex(where: { $0.id == id && !$0.popped }) else { return }
        bubbles[idx].popped = true
        let bubble = bubbles[idx]
        if bubble.color == lastPoppedColor { combo += 1 } else { combo = 1 }
        lastPoppedColor = bubble.color
        let basePoints = Int(100.0 / bubble.size * 10)
        let comboMultiplier = min(combo, 5)
        score += basePoints * comboMultiplier
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
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: 0, badgeUnlocked: score >= 500 ? "Bubble Buster" : nil)
    }

    deinit { timer?.invalidate(); spawnTimer?.invalidate() }
}
