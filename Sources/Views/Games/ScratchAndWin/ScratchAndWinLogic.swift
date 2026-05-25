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
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0

    let cardCost = 50

    enum GamePhase { case lobby, playing, results }

    func buyCard() {
        do { try CurrencyLedger.shared.spendCoins(cardCost) } catch { return }
        tiles = (0..<9).map { _ in (symbol: ScratchSymbol.randomSymbol(), revealed: false) }
        lastWin = 0
        phase = .playing
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
        for (icon, count) in counts where count >= 3 {
            if let sym = ScratchSymbol.allSymbols.first(where: { $0.icon == icon }) {
                maxWin = max(maxWin, sym.prize)
            }
        }
        if maxWin > 0 {
            lastWin = maxWin; score += maxWin
            CurrencyLedger.shared.awardCoins(maxWin, reason: "Scratch card win")
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else { streakMultiplier = 1.0 }
        phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward) * streakMultiplier) + (score / 10)
        return GameReward(xp: max(1, xp), coins: 0, gems: 0, badgeUnlocked: lastWin >= 5000 ? "Lucky Scratcher" : nil)
    }
}
