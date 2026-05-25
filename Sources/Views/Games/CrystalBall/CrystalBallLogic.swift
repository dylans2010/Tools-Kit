import Foundation

final class CrystalBallLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "crystal_ball"
    let baseXPReward = 15; let winXPBonus = 10; let baseCoinReward = 10; let winCoinBonus = 5

    enum GamePhase { case lobby, playing, results }
    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var won = false; @Published var round = 0; @Published var totalRounds = 10
    @Published var balance = 500; @Published var predictions = 0
    @Published var totalWon = 0; @Published var biggestWin = 0
    @Published var consecutiveWins = 0; @Published var bestStreak = 0
    @Published var lastPrize = ""; @Published var canOpen = true

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; balance = 500 + difficulty * 200
        totalRounds = 10 + difficulty * 5; round = 0; score = 0; predictions = 0
        totalWon = 0; biggestWin = 0; consecutiveWins = 0; bestStreak = 0
        streakMultiplier = 1.0; won = false; canOpen = true; lastPrize = ""
        phase = .playing
    }

    func openPrize() {
        guard canOpen, round < totalRounds else { return }
        round += 1; canOpen = false; predictions += 1
        let cost = 25 + difficulty * 15; balance -= cost

        let roll = Double.random(in: 0...1)
        let prizes: [(Double, Int, String)]
        switch difficulty {
        case 0: prizes = [(0.4, cost * 2, "Common"), (0.25, cost * 3, "Uncommon"), (0.1, cost * 5, "Rare"), (0.03, cost * 10, "Epic")]
        case 1: prizes = [(0.35, cost * 2, "Common"), (0.25, cost * 3, "Uncommon"), (0.12, cost * 5, "Rare"), (0.05, cost * 10, "Epic"), (0.01, cost * 20, "Legendary")]
        default: prizes = [(0.30, cost * 2, "Common"), (0.20, cost * 4, "Uncommon"), (0.15, cost * 6, "Rare"), (0.08, cost * 12, "Epic"), (0.02, cost * 25, "Legendary")]
        }

        var cumulative: Double = 0
        var prize = 0; var rarity = "Nothing"
        for (chance, value, name) in prizes {
            cumulative += chance
            if roll <= cumulative { prize = value; rarity = name; break }
        }

        if prize > 0 {
            balance += prize; totalWon += prize; biggestWin = max(biggestWin, prize)
            consecutiveWins += 1; bestStreak = max(bestStreak, consecutiveWins)
            score += Int(Double(prize) * streakMultiplier)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            lastPrize = "\(rarity)! +\(prize)"
        } else {
            consecutiveWins = 0; streakMultiplier = max(1.0, streakMultiplier - 0.05)
            lastPrize = "Empty..."
        }

        if round >= totalRounds || balance <= 0 { won = balance > 500; phase = .results }
        else { DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in self?.canOpen = true } }
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if biggestWin >= 500 { badge = "Jackpot Winner" }
        if bestStreak >= 5 { badge = badge ?? "Lucky Streak" }
        if totalWon >= 2000 { badge = badge ?? "Crystal Ball Tycoon" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
