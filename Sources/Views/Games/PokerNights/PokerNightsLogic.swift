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

    private var deck = CardDeck()
    private let blind = 20

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        roundWins = 0; score = 0; currentRound = 0; gameOver = false; phase = .playing
        dealRound()
    }

    func dealRound() {
        deck = CardDeck()
        currentRound += 1; pot = 0; roundResult = ""; showdown = false
        players = [
            PokerPlayer(id: 0, name: "You", hand: [deck.draw()!, deck.draw()!, deck.draw()!, deck.draw()!, deck.draw()!], chips: 1000, folded: false, currentBet: blind, isHuman: true),
            PokerPlayer(id: 1, name: "AI Rex", hand: [deck.draw()!, deck.draw()!, deck.draw()!, deck.draw()!, deck.draw()!], chips: 1000, folded: false, currentBet: blind, isHuman: false),
            PokerPlayer(id: 2, name: "AI Luna", hand: [deck.draw()!, deck.draw()!, deck.draw()!, deck.draw()!, deck.draw()!], chips: 1000, folded: false, currentBet: blind, isHuman: false),
            PokerPlayer(id: 3, name: "AI Max", hand: [deck.draw()!, deck.draw()!, deck.draw()!, deck.draw()!, deck.draw()!], chips: 1000, folded: false, currentBet: blind, isHuman: false),
        ]
        pot = blind * 4
    }

    func raise(amount: Int) {
        guard amount >= blind, let idx = players.firstIndex(where: { $0.isHuman }) else { return }
        players[idx].currentBet += amount; players[idx].chips -= amount; pot += amount
        aiRespond()
    }

    func call() {
        aiRespond()
    }

    func fold() {
        if let idx = players.firstIndex(where: { $0.isHuman }) { players[idx].folded = true }
        roundResult = "You folded."; endRound()
    }

    private func aiRespond() {
        for i in 1..<players.count where !players[i].folded {
            let eval = PokerHandEvaluator.evaluate(players[i].hand)
            let strength = eval.rank.rawValue
            if strength >= PokerHandRank.pair.rawValue {
                let raiseAmt = min(players[i].chips, blind * (strength + 1))
                players[i].currentBet += raiseAmt; players[i].chips -= raiseAmt; pot += raiseAmt
            } else if Double.random(in: 0...1) < 0.3 {
                let bluffAmt = min(players[i].chips, blind * 2)
                players[i].currentBet += bluffAmt; players[i].chips -= bluffAmt; pot += bluffAmt
            } else if strength == 0 && Double.random(in: 0...1) < 0.2 {
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
            score += pot; roundWins += 1; streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else {
            roundResult = "\(best.name) wins with \(eval.rank.name)"
            streakMultiplier = 1.0
        }
        endRound()
    }

    private func endRound() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            if self.currentRound >= 10 { self.gameOver = true; self.phase = .results }
        }
    }

    func nextRound() { if !gameOver { dealRound() } }

    func finalReward() -> GameReward {
        let won = roundWins > 0
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let gems = roundWins >= 10 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: 0, gems: gems, badgeUnlocked: roundWins >= 5 ? "Poker Champion" : nil)
    }
}
