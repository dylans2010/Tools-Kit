import Foundation

final class LotteryDrawLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "lottery_draw"
    let baseXPReward = 20; let winXPBonus = 10; let baseCoinReward = 10; let winCoinBonus = 5

    enum GamePhase { case lobby, playing, results }
    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var won = false; @Published var round = 0; @Published var totalRounds = 10
    @Published var balance = 500; @Published var betAmount = 50
    @Published var roundResult = ""; @Published var roundOver = false
    @Published var consecutiveWins = 0; @Published var bestStreak = 0
    @Published var totalWon = 0; @Published var biggestWin = 0; @Published var handsWon = 0
    @Published var currentValue = 0; @Published var targetValue = 0
    @Published var selectedNumbers: Set<Int> = []; @Published var drawnNumbers: Set<Int> = []
    @Published var showResult = false

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; balance = 500 + difficulty * 200
        betAmount = [50, 75, 100][difficulty]; totalRounds = 10 + difficulty * 5
        round = 0; score = 0; totalWon = 0; biggestWin = 0; handsWon = 0
        consecutiveWins = 0; bestStreak = 0; streakMultiplier = 1.0; won = false
        phase = .playing; newRound()
    }

    func newRound() {
        round += 1; roundOver = false; roundResult = ""; showResult = false
        currentValue = Int.random(in: 1...100)
        targetValue = Int.random(in: 1...100)
        selectedNumbers = []; drawnNumbers = []
    }

    func guessHigher() { resolve(currentValue < targetValue) }
    func guessLower() { resolve(currentValue > targetValue) }

    func selectNumber(_ n: Int) {
        if selectedNumbers.count < 5 + difficulty * 2 { selectedNumbers.insert(n) }
    }

    func draw() {
        drawnNumbers = Set((0..<20).map { _ in Int.random(in: 1...40) })
        let matches = selectedNumbers.intersection(drawnNumbers).count
        if matches >= 3 { resolve(true, payout: matches * betAmount) }
        else { resolve(false) }
    }

    func flipCoin() {
        let result = Bool.random()
        resolve(result, payout: result ? betAmount * 2 : 0)
    }

    func spinWheel() {
        let prizes = [0, betAmount, betAmount * 2, betAmount * 3, betAmount * 5, 0, betAmount, 0]
        let idx = Int.random(in: 0..<prizes.count)
        let prize = prizes[idx]
        resolve(prize > 0, payout: prize)
    }

    func resolve(_ playerWins: Bool, payout: Int = 0) {
        roundOver = true; showResult = true
        let winAmount = payout > 0 ? payout : betAmount * 2
        if playerWins {
            balance += winAmount; handsWon += 1; consecutiveWins += 1
            bestStreak = max(bestStreak, consecutiveWins)
            totalWon += winAmount; biggestWin = max(biggestWin, winAmount)
            score += Int(Double(winAmount) * streakMultiplier)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            roundResult = "Won \(winAmount)!"
        } else {
            balance -= betAmount; consecutiveWins = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.05)
            roundResult = "Lost \(betAmount)"
        }
        if round >= totalRounds || balance <= 0 { won = balance > 500; phase = .results }
    }

    func nextRound() { newRound() }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if handsWon >= totalRounds / 2 { badge = "Lottery Draw Pro" }
        if bestStreak >= 5 { badge = badge ?? "Hot Streak" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
