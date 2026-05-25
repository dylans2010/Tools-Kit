import Foundation

enum RouletteBetType: String, CaseIterable {
    case straight = "Straight"
    case red = "Red"
    case black = "Black"
    case odd = "Odd"
    case even = "Even"
    case low = "Low (1-18)"
    case high = "High (19-36)"
    case dozen1 = "1st Dozen"
    case dozen2 = "2nd Dozen"
    case dozen3 = "3rd Dozen"

    var payout: Int {
        switch self {
        case .straight: return 35
        case .dozen1, .dozen2, .dozen3: return 2
        case .red, .black, .odd, .even, .low, .high: return 1
        }
    }
}

final class RouletteRoyalLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "roulette_royal"
    let baseXPReward = 25
    let winXPBonus = 0
    let baseCoinReward = 0
    let winCoinBonus = 0

    static let redNumbers = [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36]
    @Published var selectedBetType: RouletteBetType = .red
    @Published var straightNumber = 0
    @Published var bet = 25
    @Published var result: Int?
    @Published var lastWin = 0
    @Published var totalWon = 0
    @Published var totalLost = 0
    @Published var spins = 0
    @Published var isSpinning = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var score = 0
    @Published var consecutiveWins = 0
    @Published var bestConsecutiveWins = 0
    @Published var biggestWin = 0
    @Published var history: [Int] = []
    @Published var freeSpinsAvailable = 0

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        totalWon = 0; totalLost = 0; spins = 0; score = 0; consecutiveWins = 0
        bestConsecutiveWins = 0; biggestWin = 0; history = []; freeSpinsAvailable = 0
        phase = .playing
    }

    func spin() {
        let isFree = freeSpinsAvailable > 0
        if !isFree {
            let balance = CurrencyLedger.shared.profile.coins
            guard bet <= balance, bet >= 5, !isSpinning else { return }
            do { try CurrencyLedger.shared.spendCoins(bet) } catch { return }
        } else {
            guard !isSpinning else { return }
            freeSpinsAvailable -= 1
        }
        isSpinning = true; spins += 1
        let finalResult = Int.random(in: 0...36)
        var animCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            animCount += 1
            self.result = Int.random(in: 0...36)
            if animCount >= 20 { timer.invalidate(); self.result = finalResult; self.resolveOutcome(finalResult) }
        }
    }

    private func resolveOutcome(_ number: Int) {
        isSpinning = false
        history.append(number)
        if history.count > 20 { history.removeFirst() }
        let isRed = Self.redNumbers.contains(number)
        var won = false
        switch selectedBetType {
        case .straight: won = number == straightNumber
        case .red: won = isRed
        case .black: won = number != 0 && !isRed
        case .odd: won = number != 0 && number % 2 != 0
        case .even: won = number != 0 && number % 2 == 0
        case .low: won = number >= 1 && number <= 18
        case .high: won = number >= 19 && number <= 36
        case .dozen1: won = number >= 1 && number <= 12
        case .dozen2: won = number >= 13 && number <= 24
        case .dozen3: won = number >= 25 && number <= 36
        }
        if won {
            let winAmount = bet * (selectedBetType.payout + 1)
            lastWin = winAmount; totalWon += winAmount; score += winAmount
            biggestWin = max(biggestWin, winAmount)
            consecutiveWins += 1
            bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
            CurrencyLedger.shared.awardCoins(winAmount, reason: "Roulette win: \(selectedBetType.rawValue)")
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            if consecutiveWins >= 3 && consecutiveWins % 3 == 0 { freeSpinsAvailable += 1 }
        } else {
            lastWin = 0; totalLost += bet; consecutiveWins = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.1)
        }
    }

    func endSession() { phase = .results }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward * spins) * streakMultiplier)
        var badge: String?
        if biggestWin >= 500 { badge = "Big Winner" }
        if bestConsecutiveWins >= 5 { badge = badge ?? "Lucky Streak" }
        if totalWon >= 2000 { badge = badge ?? "Roulette Royalty" }
        if selectedBetType == .straight && lastWin > 0 { badge = badge ?? "Straight Shooter" }
        let gems = biggestWin >= 1000 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: 0, gems: gems, badgeUnlocked: badge)
    }
}
