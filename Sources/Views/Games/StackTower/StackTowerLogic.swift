import Foundation

final class StackTowerLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "stack_tower"
    let baseXPReward = 20; let winXPBonus = 15; let baseCoinReward = 12; let winCoinBonus = 8

    enum GamePhase { case lobby, playing, results }
    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var won = false; @Published var timeRemaining: Double = 30
    @Published var targets: [TargetItem] = []; @Published var blocksStacked = 0
    @Published var consecutiveHits = 0; @Published var bestStreak = 0; @Published var misses = 0

    private var gameTimer: Timer?; private var spawnTimer: Timer?

    struct TargetItem: Identifiable {
        let id = UUID(); var position: Int; var points: Int; var active: Bool
    }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; timeRemaining = 30 + Double(difficulty) * 10
        score = 0; blocksStacked = 0; misses = 0; consecutiveHits = 0; bestStreak = 0
        streakMultiplier = 1.0; won = false; targets = []; phase = .playing; startTimers()
    }

    private func startTimers() {
        gameTimer?.invalidate(); spawnTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 { self.endGame() }
        }
        let interval = max(0.5, 1.5 - Double(difficulty) * 0.3)
        spawnTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.spawnTarget()
        }
    }

    private func spawnTarget() {
        if targets.filter({ $0.active }).count >= 4 + difficulty {
            if let idx = targets.firstIndex(where: { $0.active }) {
                targets[idx] = TargetItem(position: targets[idx].position, points: targets[idx].points, active: false)
                misses += 1; consecutiveHits = 0; streakMultiplier = max(1.0, streakMultiplier - 0.05)
            }
        }
        targets.append(TargetItem(position: Int.random(in: 0..<12), points: 20 + difficulty * 10, active: true))
    }

    func tap(_ item: TargetItem) {
        guard let idx = targets.firstIndex(where: { $0.id == item.id && $0.active }) else { return }
        targets[idx] = TargetItem(position: item.position, points: item.points, active: false)
        blocksStacked += 1; consecutiveHits += 1; bestStreak = max(bestStreak, consecutiveHits)
        score += Int(Double(item.points) * streakMultiplier)
        streakMultiplier = min(3.0, streakMultiplier + 0.08)
    }

    private func endGame() {
        gameTimer?.invalidate(); spawnTimer?.invalidate()
        won = blocksStacked >= 10 + difficulty * 5; phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if blocksStacked >= 25 { badge = "Stack Tower Star" }
        if bestStreak >= 10 { badge = badge ?? "Combo Master" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }

    deinit { gameTimer?.invalidate(); spawnTimer?.invalidate() }
}
