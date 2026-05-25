import Foundation

struct PokerPlayer: Identifiable {
    let id: Int
    let name: String
    var hand: [PlayingCard]
    var chips: Int
    var folded: Bool
    var currentBet: Int
    var isHuman: Bool
}

final class PokerNightsLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "poker_nights"
    let baseXPReward = 80
    let winXPBonus = 120
    let baseCoinReward = 0
    let winCoinBonus = 0

    @Published var players: [PokerPlayer] = []
    @Published var pot = 0
    @Published var communityCards: [PlayingCard] = []
    @Published var currentRound = 0
    @Published var roundWins = 0
    @Published var score = 0
    @Published var gameOver = false
    @Published var roundResult = ""
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var showdown = false
    @Published var difficulty = 0
    @Published var consecutiveWins = 0
    @Published var bestConsecutiveWins = 0
    @Published var biggestPot = 0
    @Published var bluffsAttempted = 0
    @Published var totalRounds = 10
    @Published var bestHand = ""

    private var deck = CardDeck()
    private let blind = 20

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        roundWins = 0; score = 0; currentRound = 0; gameOver = false
        consecutiveWins = 0; bestConsecutiveWins = 0; biggestPot = 0; bluffsAttempted = 0
        bestHand = ""
        totalRounds = 10 + difficulty * 3
        phase = .playing; dealRound()
    }

    func dealRound() {
        deck = CardDeck()
        currentRound += 1; pot = 0; roundResult = ""; showdown = false
        let opponentCount = 3 + min(difficulty, 2)
        var playerList = [PokerPlayer(id: 0, name: "You", hand: (0..<5).compactMap { _ in deck.draw() },
                                      chips: 1000, folded: false, currentBet: blind, isHuman: true)]
        let aiNames = ["Rex", "Luna", "Max", "Zara", "Ace"]
        for i in 0..<opponentCount {
            playerList.append(PokerPlayer(id: i + 1, name: "AI \(aiNames[i % aiNames.count])",
                                          hand: (0..<5).compactMap { _ in deck.draw() },
                                          chips: 1000, folded: false, currentBet: blind, isHuman: false))
        }
        players = playerList
        pot = blind * players.count
    }

    func raise(amount: Int) {
        guard amount >= blind, let idx = players.firstIndex(where: { $0.isHuman }) else { return }
        players[idx].currentBet += amount; players[idx].chips -= amount; pot += amount
        aiRespond()
    }

    func call() { aiRespond() }

    func fold() {
        if let idx = players.firstIndex(where: { $0.isHuman }) { players[idx].folded = true }
        roundResult = "You folded."; consecutiveWins = 0; endRound()
    }

    func bluff(amount: Int) {
        guard let idx = players.firstIndex(where: { $0.isHuman }) else { return }
        bluffsAttempted += 1
        players[idx].currentBet += amount; players[idx].chips -= amount; pot += amount
        let bluffStrength = Double.random(in: 0...1)
        let bluffSuccess = bluffStrength > (0.3 + Double(difficulty) * 0.15)
        if bluffSuccess {
            for i in 1..<players.count where !players[i].folded {
                if Double.random(in: 0...1) < 0.4 + Double(difficulty) * 0.1 {
                    players[i].folded = true
                }
            }
        }
        let active = players.filter { !$0.folded }
        if active.count == 1 && active[0].isHuman {
            roundResult = "Everyone folded! You win \(pot) coins!"
            CurrencyLedger.shared.awardCoins(pot, reason: "Poker bluff win")
            score += pot; roundWins += 1; consecutiveWins += 1
            bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
            biggestPot = max(biggestPot, pot)
            streakMultiplier = min(3.0, streakMultiplier + 0.15)
            endRound()
        } else {
            aiRespond()
        }
    }

    private func aiRespond() {
        for i in 1..<players.count where !players[i].folded {
            let eval = PokerHandEvaluator.evaluate(players[i].hand)
            let strength = eval.rank.rawValue
            let difficultyFactor = difficulty >= 1 ? 1.5 : 1.0
            if strength >= PokerHandRank.pair.rawValue {
                let raiseAmt = min(players[i].chips, Int(Double(blind * (strength + 1)) * difficultyFactor))
                players[i].currentBet += raiseAmt; players[i].chips -= raiseAmt; pot += raiseAmt
            } else if Double.random(in: 0...1) < (0.3 + Double(difficulty) * 0.1) {
                let bluffAmt = min(players[i].chips, blind * 2)
                players[i].currentBet += bluffAmt; players[i].chips -= bluffAmt; pot += bluffAmt
            } else if strength == 0 && Double.random(in: 0...1) < (0.2 - Double(difficulty) * 0.05) {
                players[i].folded = true
            }
        }
        resolveShowdown()
    }

    private func resolveShowdown() {
        showdown = true
        let active = players.filter { !$0.folded }
        guard !active.isEmpty else { endRound(); return }
        let best = active.max { PokerHandEvaluator.evaluate($0.hand) < PokerHandEvaluator.evaluate($1.hand) }!
        let eval = PokerHandEvaluator.evaluate(best.hand)
        if best.isHuman {
            roundResult = "You win with \(eval.rank.name)! +\(pot) coins"
            CurrencyLedger.shared.awardCoins(pot, reason: "Poker win")
            score += pot; roundWins += 1; consecutiveWins += 1
            bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
            biggestPot = max(biggestPot, pot)
            if bestHand.isEmpty || eval.rank.rawValue > PokerHandRank.allCases.firstIndex(where: { $0.name == bestHand }) ?? 0 {
                bestHand = eval.rank.name
            }
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else {
            roundResult = "\(best.name) wins with \(eval.rank.name)"
            consecutiveWins = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.1)
        }
        endRound()
    }

    private func endRound() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            if self.currentRound >= self.totalRounds { self.gameOver = true; self.phase = .results }
        }
    }

    func nextRound() { if !gameOver { dealRound() } }

    func finalReward() -> GameReward {
        let won = roundWins > 0
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let diffBonus = difficulty * 30
        var badge: String?
        if roundWins >= totalRounds { badge = "Poker Legend" }
        if bestConsecutiveWins >= 5 { badge = badge ?? "Poker Streak" }
        if roundWins >= 5 { badge = badge ?? "Poker Champion" }
        if biggestPot >= 500 { badge = badge ?? "High Roller" }
        if bluffsAttempted >= 3 && roundWins >= totalRounds / 2 { badge = badge ?? "Bluff Master" }
        let gems = roundWins >= totalRounds / 2 && difficulty >= 1 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: 0, gems: gems, badgeUnlocked: badge)
    }
}
