import Foundation

final class DiceRollFortuneLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "dice_roll_fortune"
    let baseXPReward = 20
    let winXPBonus = 35
    let baseCoinReward = 0
    let winCoinBonus = 0

    @Published var dice: [Int] = [1, 1]
    @Published var diceCount = 2
    @Published var bet = 20
    @Published var lastWin = 0
    @Published var totalWon = 0
    @Published var rolls = 0
    @Published var isRolling = false
    @Published var combination = ""
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var score = 0
    @Published var consecutiveWins = 0
    @Published var bestConsecutiveWins = 0
    @Published var biggestWin = 0
    @Published var jackpotProgress: Double = 0
    @Published var freeRollsAvailable = 0

    enum GamePhase { case lobby, playing, results }

    var jackpotAmount: Int {
        let gameLevel = CurrencyLedger.shared.gameStats(for: gameIdentifier).gameLevel
        return 5000 + gameLevel * 500
    }

    func startGame() {
        totalWon = 0; rolls = 0; score = 0; consecutiveWins = 0; bestConsecutiveWins = 0
        biggestWin = 0; jackpotProgress = 0; freeRollsAvailable = 0; phase = .playing
    }

    func roll() {
        let isFree = freeRollsAvailable > 0
        if !isFree {
            guard bet <= CurrencyLedger.shared.profile.coins, !isRolling else { return }
            do { try CurrencyLedger.shared.spendCoins(bet) } catch { return }
        } else {
            guard !isRolling else { return }
            freeRollsAvailable -= 1
        }
        isRolling = true; rolls += 1; jackpotProgress = min(1.0, jackpotProgress + 0.03)
        var animCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            animCount += 1
            self.dice = (0..<self.diceCount).map { _ in Int.random(in: 1...6) }
            if animCount >= 15 { timer.invalidate(); self.isRolling = false; self.evaluateDice() }
        }
    }

    private func evaluateDice() {
        let sorted = dice.sorted()
        let counts = dice.reduce(into: [Int: Int]()) { $0[$1, default: 0] += 1 }
        let maxCount = counts.values.max() ?? 0
        var multiplier = 0.0

        if jackpotProgress >= 1.0 && Bool.random() && Bool.random() && Bool.random() {
            combination = "JACKPOT!"; multiplier = Double(jackpotAmount) / Double(max(1, bet))
            jackpotProgress = 0
        } else if maxCount == diceCount { combination = "All Same!"; multiplier = 10.0 }
        else if maxCount >= 3 && counts.values.contains(2) { combination = "Full House"; multiplier = 5.0 }
        else if maxCount >= 3 { combination = "Three of a Kind"; multiplier = 3.0 }
        else if diceCount >= 4 && sorted == Array(sorted[0]...sorted[0]+diceCount-1) { combination = "Straight"; multiplier = 6.0 }
        else if counts.values.filter({ $0 == 2 }).count >= 2 { combination = "Two Pair"; multiplier = 2.0 }
        else if maxCount == 2 { combination = "Pair"; multiplier = 1.5 }
        else { combination = "No match"; multiplier = 0 }

        if multiplier > 0 {
            let winAmount = Int(Double(bet) * multiplier)
            lastWin = winAmount; totalWon += winAmount; score += winAmount
            biggestWin = max(biggestWin, winAmount)
            consecutiveWins += 1
            bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
            CurrencyLedger.shared.awardCoins(winAmount, reason: "Dice \(combination)")
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            if consecutiveWins >= 3 && consecutiveWins % 3 == 0 { freeRollsAvailable += 1 }
        } else {
            lastWin = 0; consecutiveWins = 0; streakMultiplier = max(1.0, streakMultiplier - 0.1)
        }
    }

    func endSession() { phase = .results }

    func finalReward() -> GameReward {
        let won = totalWon > 0
        let xp = Int(Double(baseXPReward * rolls + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        var badge: String?
        if biggestWin >= jackpotAmount { badge = "Jackpot Winner" }
        if bestConsecutiveWins >= 5 { badge = badge ?? "Lucky Roller" }
        if totalWon >= 2000 { badge = badge ?? "Dice Master" }
        let gems = biggestWin >= jackpotAmount ? 1 : 0
        return GameReward(xp: max(1, xp), coins: 0, gems: gems, badgeUnlocked: badge)
    }
}
