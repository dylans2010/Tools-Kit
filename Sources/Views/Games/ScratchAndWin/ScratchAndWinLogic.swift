import Foundation

struct ScratchSymbol: Equatable {
    let icon: String
    let rarity: Double
    let prize: Int
    static let allSymbols: [ScratchSymbol] = [
        ScratchSymbol(icon: "star.fill", rarity: 0.30, prize: 50),
        ScratchSymbol(icon: "heart.fill", rarity: 0.25, prize: 100),
        ScratchSymbol(icon: "bolt.fill", rarity: 0.20, prize: 200),
        ScratchSymbol(icon: "diamond.fill", rarity: 0.13, prize: 500),
        ScratchSymbol(icon: "crown.fill", rarity: 0.08, prize: 1000),
        ScratchSymbol(icon: "gift.fill", rarity: 0.04, prize: 5000),
    ]

    static func randomSymbol() -> ScratchSymbol {
        let r = Double.random(in: 0...1)
        var cumulative = 0.0
        for sym in allSymbols {
            cumulative += sym.rarity
            if r <= cumulative { return sym }
        }
        return allSymbols[0]
    }
}

final class ScratchAndWinLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "scratch_and_win"
    let baseXPReward = 15
    let winXPBonus = 0
    let baseCoinReward = 0
    let winCoinBonus = 0

    @Published var tiles: [(symbol: ScratchSymbol, revealed: Bool)] = []
    @Published var score = 0
    @Published var lastWin = 0
    @Published var freeCardsAvailable: Int = 0
    @Published var cardsScratched: Int = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var cardsPlayed = 0
    @Published var totalWinnings = 0
    @Published var biggestWin = 0
    @Published var matchCount = 0
    @Published var consecutiveWins = 0
    @Published var bestConsecutiveWins = 0
    @Published var freeCardAvailable = false
    @Published var cardTier = 0

    let cardCosts = [50, 100, 250]
    var cardCost: Int { cardCosts[min(cardTier, cardCosts.count - 1)] }

    enum GamePhase { case lobby, playing, results }

    func buyCard(tier: Int = 0) {
        cardTier = tier
        let cost = cardCosts[min(tier, cardCosts.count - 1)]
        if !freeCardAvailable {
            do { try CurrencyLedger.shared.spendCoins(cost) } catch { return }
        } else {
            freeCardAvailable = false
        }
        cardsPlayed += 1
        let multiplier = 1.0 + Double(tier) * 0.5
        tiles = (0..<9).map { _ in
            var sym = ScratchSymbol.randomSymbol()
            if tier >= 1 && Double.random(in: 0...1) < 0.1 {
                sym = ScratchSymbol.allSymbols.last!
            }
            return (symbol: ScratchSymbol(icon: sym.icon, rarity: sym.rarity, prize: Int(Double(sym.prize) * multiplier)),
                    revealed: false)
        }
        lastWin = 0; phase = .playing
    }

    func revealTile(_ index: Int) {
        guard index < tiles.count, !tiles[index].revealed else { return }
        tiles[index].revealed = true
        if tiles.filter({ $0.revealed }).count == tiles.count { evaluateCard() }
    }

    func revealAll() {
        for i in tiles.indices { tiles[i].revealed = true }
        evaluateCard()
    }

    private func evaluateCard() {
        let icons = tiles.map { $0.symbol.icon }
        let counts = icons.reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        var maxWin = 0
        var matches = 0
        for (icon, count) in counts where count >= 3 {
            if let sym = tiles.first(where: { $0.symbol.icon == icon }) {
                maxWin = max(maxWin, sym.symbol.prize)
                matches += 1
            }
        }
        matchCount += matches
        if maxWin > 0 {
            lastWin = maxWin; score += maxWin; totalWinnings += maxWin
            biggestWin = max(biggestWin, maxWin)
            consecutiveWins += 1
            bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
            CurrencyLedger.shared.awardCoins(maxWin, reason: "Scratch card win")
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            if consecutiveWins >= 3 { freeCardAvailable = true }
        } else {
            consecutiveWins = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.1)
        }
        phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward) * streakMultiplier) + (score / 10)
        var badge: String?
        if lastWin >= 5000 { badge = "Lucky Scratcher" }
        if biggestWin >= 1000 { badge = badge ?? "Big Scratch Win" }
        if bestConsecutiveWins >= 3 { badge = badge ?? "Scratch Streak" }
        if totalWinnings >= 2000 { badge = badge ?? "Scratch Master" }
        let gems = biggestWin >= 5000 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: 0, gems: gems, badgeUnlocked: badge)
    }
}
