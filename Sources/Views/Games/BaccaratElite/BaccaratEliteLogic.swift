import Foundation

final class BaccaratEliteLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "baccarat_elite"
    let baseXPReward = 20; let winXPBonus = 15; let baseCoinReward = 10; let winCoinBonus = 5

    enum GamePhase { case lobby, playing, results }
    enum BetType: String { case player = "Player", banker = "Banker", tie = "Tie" }

    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var won = false; @Published var round = 0; @Published var totalRounds = 10
    @Published var bet: BetType?; @Published var betAmount = 50
    @Published var playerCards: [Int] = []; @Published var bankerCards: [Int] = []
    @Published var playerTotal = 0; @Published var bankerTotal = 0
    @Published var result = ""; @Published var roundOver = false
    @Published var balance = 500; @Published var handsWon = 0; @Published var consecutiveWins = 0
    @Published var bestStreak = 0; @Published var biggestWin = 0

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; balance = 500 + difficulty * 200
        totalRounds = 10 + difficulty * 5; round = 0; score = 0; handsWon = 0
        consecutiveWins = 0; bestStreak = 0; biggestWin = 0; won = false
        streakMultiplier = 1.0; phase = .playing; newHand()
    }

    func newHand() {
        round += 1; bet = nil; roundOver = false; result = ""
        playerCards = []; bankerCards = []
    }

    func placeBet(_ type: BetType) {
        guard !roundOver else { return }
        bet = type; deal()
    }

    private func deal() {
        playerCards = [drawCard(), drawCard()]; bankerCards = [drawCard(), drawCard()]
        playerTotal = handValue(playerCards); bankerTotal = handValue(bankerCards)
        if playerTotal <= 5 { playerCards.append(drawCard()); playerTotal = handValue(playerCards) }
        if bankerTotal <= 5 { bankerCards.append(drawCard()); bankerTotal = handValue(bankerCards) }
        resolveHand()
    }

    private func drawCard() -> Int { Int.random(in: 1...13) }

    private func handValue(_ cards: [Int]) -> Int {
        let total = cards.reduce(0) { $0 + min($1, 10) }
        return total % 10
    }

    private func resolveHand() {
        roundOver = true
        let winner: BetType = playerTotal > bankerTotal ? .player : (bankerTotal > playerTotal ? .banker : .tie)
        if bet == winner {
            let payout = bet == .tie ? betAmount * 8 : betAmount * 2
            balance += payout; handsWon += 1; consecutiveWins += 1
            bestStreak = max(bestStreak, consecutiveWins)
            biggestWin = max(biggestWin, payout)
            score += Int(Double(payout) * streakMultiplier)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            result = "You win \(payout)!"
        } else {
            balance -= betAmount; consecutiveWins = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.05)
            result = "\(winner.rawValue) wins"
        }
        if round >= totalRounds || balance <= 0 { won = balance > 500; phase = .results }
    }

    func nextHand() { newHand() }

    func cardDisplay(_ val: Int) -> String {
        switch val {
        case 1: return "A"; case 11: return "J"; case 12: return "Q"; case 13: return "K"
        default: return "\(val)"
        }
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if handsWon >= 8 { badge = "Baccarat Master" }
        if bestStreak >= 5 { badge = badge ?? "Lucky Streak" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
