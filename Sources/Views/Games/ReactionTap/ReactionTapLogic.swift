import Foundation

final class ReactionTapLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "reaction_tap"
    let baseXPReward = 20
    let winXPBonus = 0
    let baseCoinReward = 10
    let winCoinBonus = 0

    @Published var isGreen = false
    @Published var waiting = false
    @Published var tooEarly = false
    @Published var reactionTime: Double?
    @Published var bestTime: Double = 999
    @Published var round = 0
    @Published var totalRounds = 5
    @Published var times: [Double] = []
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var score = 0
    @Published var difficulty = 0
    @Published var tooEarlyCount = 0
    @Published var perfectCount = 0
    @Published var consecutiveFast = 0
    @Published var bestConsecutiveFast = 0

    private var signalTime: Date?
    private var delayTimer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        totalRounds = 5 + difficulty * 3
        round = 0; times = []; bestTime = 999; score = 0
        tooEarlyCount = 0; perfectCount = 0; consecutiveFast = 0; bestConsecutiveFast = 0
        phase = .playing; nextRound()
    }

    func nextRound() {
        round += 1; isGreen = false; waiting = true; tooEarly = false; reactionTime = nil
        let minDelay = 1.5 - Double(difficulty) * 0.2
        let maxDelay = 5.0 - Double(difficulty) * 0.5
        let delay = Double.random(in: max(0.8, minDelay)...max(2.0, maxDelay))
        delayTimer?.invalidate()
        delayTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.isGreen = true; self.signalTime = Date()
        }
    }

    func tap() {
        if !waiting { return }
        if !isGreen {
            tooEarly = true; waiting = false; delayTimer?.invalidate()
            tooEarlyCount += 1; consecutiveFast = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self else { return }
                if self.round < self.totalRounds { self.nextRound() } else { self.endGame() }
            }
            return
        }
        let elapsed = Date().timeIntervalSince(signalTime ?? Date()) * 1000
        reactionTime = elapsed; times.append(elapsed); waiting = false
        bestTime = min(bestTime, elapsed)

        let basePoints = max(0, Int(500 - elapsed))
        let speedBonus = elapsed < 200 ? 100 : (elapsed < 300 ? 50 : 0)
        score += basePoints + speedBonus

        if elapsed < 200 { perfectCount += 1 }
        if elapsed < 300 {
            consecutiveFast += 1
            bestConsecutiveFast = max(bestConsecutiveFast, consecutiveFast)
        } else {
            consecutiveFast = 0
        }

        streakMultiplier = min(3.0, streakMultiplier + (elapsed < 250 ? 0.15 : 0.05))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            if self.round < self.totalRounds { self.nextRound() } else { self.endGame() }
        }
    }

    private func endGame() { phase = .results }

    var averageTime: Double {
        times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 20)
        let diffBonus = difficulty * 10
        var badge: String?
        if bestTime < 200 { badge = "Lightning Reflexes" }
        if bestTime < 150 { badge = badge ?? "Superhuman" }
        if perfectCount >= totalRounds { badge = badge ?? "Perfect Reflexes" }
        if bestConsecutiveFast >= 5 { badge = badge ?? "Reflex Streak" }
        if tooEarlyCount == 0 && times.count == totalRounds { badge = badge ?? "Patient Tapper" }
        let gems = bestTime < 150 && difficulty >= 1 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }

    deinit { delayTimer?.invalidate() }
}
