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

    private var signalTime: Date?
    private var delayTimer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        round = 0; times = []; bestTime = 999; score = 0; phase = .playing; nextRound()
    }

    func nextRound() {
        round += 1; isGreen = false; waiting = true; tooEarly = false; reactionTime = nil
        let delay = Double.random(in: 1.5...5.0)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self else { return }
                if self.round < self.totalRounds { self.nextRound() } else { self.endGame() }
            }
            return
        }
        let elapsed = Date().timeIntervalSince(signalTime ?? Date()) * 1000
        reactionTime = elapsed; times.append(elapsed); waiting = false
        bestTime = min(bestTime, elapsed)
        score += max(0, Int(500 - elapsed))
        streakMultiplier = min(3.0, streakMultiplier + 0.1)
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
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: 0, badgeUnlocked: bestTime < 200 ? "Lightning Reflexes" : nil)
    }

    deinit { delayTimer?.invalidate() }
}
