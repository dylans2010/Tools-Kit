import Foundation

final class WhackAMoleLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "whack_a_mole"
    let baseXPReward = 20; let winXPBonus = 15; let baseCoinReward = 12; let winCoinBonus = 8

    enum GamePhase { case lobby, playing, results }
    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var won = false; @Published var timeRemaining: Double = 30
    @Published var molePositions: Set<Int> = []; @Published var gridSize = 9
    @Published var whacked = 0; @Published var missed = 0
    @Published var consecutiveWhacks = 0; @Published var bestStreak = 0

    private var gameTimer: Timer?; private var moleTimer: Timer?

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; timeRemaining = 30 + Double(difficulty) * 10
        gridSize = 9 + difficulty * 3; score = 0; whacked = 0; missed = 0
        consecutiveWhacks = 0; bestStreak = 0; streakMultiplier = 1.0; won = false
        molePositions = []; phase = .playing; startTimers()
    }

    private func startTimers() {
        gameTimer?.invalidate(); moleTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 { self.endGame() }
        }
        let interval = max(0.4, 1.2 - Double(difficulty) * 0.3)
        moleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.spawnMole()
        }
    }

    private func spawnMole() {
        if molePositions.count >= 3 + difficulty {
            let removed = molePositions.randomElement()!
            molePositions.remove(removed); missed += 1; consecutiveWhacks = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.05)
        }
        molePositions.insert(Int.random(in: 0..<gridSize))
    }

    func whack(_ pos: Int) {
        guard molePositions.contains(pos) else { return }
        molePositions.remove(pos); whacked += 1; consecutiveWhacks += 1
        bestStreak = max(bestStreak, consecutiveWhacks)
        score += Int(Double(25 + difficulty * 10) * streakMultiplier)
        streakMultiplier = min(3.0, streakMultiplier + 0.08)
    }

    private func endGame() {
        gameTimer?.invalidate(); moleTimer?.invalidate()
        won = whacked >= 15 + difficulty * 5; phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if whacked >= 30 { badge = "Mole Hunter" }
        if bestStreak >= 10 { badge = badge ?? "Whack Streak" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }

    deinit { gameTimer?.invalidate(); moleTimer?.invalidate() }
}
