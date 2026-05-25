import Foundation

struct SlotSymbol: Equatable {
    let name: String
    let icon: String
    let multiplier: Double
    static let allSymbols: [SlotSymbol] = [
        SlotSymbol(name: "Cherry", icon: "leaf.fill", multiplier: 2.0),
        SlotSymbol(name: "Lemon", icon: "sun.max.fill", multiplier: 3.0),
        SlotSymbol(name: "Orange", icon: "circle.fill", multiplier: 4.0),
        SlotSymbol(name: "Plum", icon: "drop.fill", multiplier: 5.0),
        SlotSymbol(name: "Bell", icon: "bell.fill", multiplier: 8.0),
        SlotSymbol(name: "Bar", icon: "rectangle.fill", multiplier: 15.0),
        SlotSymbol(name: "Seven", icon: "7.circle.fill", multiplier: 30.0),
        SlotSymbol(name: "Diamond", icon: "diamond.fill", multiplier: 50.0),
    ]
}

final class SlotMachineGoldLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "slot_machine_gold"
    let baseXPReward = 30
    let winXPBonus = 0
    let baseCoinReward = 0
    let winCoinBonus = 0

    @Published var reels: [SlotSymbol] = Array(repeating: SlotSymbol.allSymbols[0], count: 3)
    @Published var bet = 50
    @Published var lastWin = 0
    @Published var totalWon = 0
    @Published var spins = 0
    @Published var isSpinning = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var score = 0

    enum GamePhase { case lobby, playing, results }

    let minBet = 10
    let maxBet = 500

    func startGame() {
        totalWon = 0
        spins = 0
        score = 0
        lastWin = 0
        phase = .playing
    }

    func spin() {
        let balance = CurrencyLedger.shared.profile.coins
        guard bet <= balance, !isSpinning else { return }
        do { try CurrencyLedger.shared.spendCoins(bet) } catch { return }

        isSpinning = true
        spins += 1

        let finalReels = (0..<3).map { _ in SlotSymbol.allSymbols.randomElement()! }
        var animStep = 0
        let totalSteps = 12
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            animStep += 1
            for i in 0..<3 {
                if animStep < totalSteps - (i * 2) {
                    self.reels[i] = SlotSymbol.allSymbols.randomElement()!
                } else {
                    self.reels[i] = finalReels[i]
                }
            }
            if animStep >= totalSteps {
                timer.invalidate()
                self.resolveOutcome(finalReels)
            }
        }
    }

    private func resolveOutcome(_ reels: [SlotSymbol]) {
        self.reels = reels
        isSpinning = false
        if reels[0].name == reels[1].name && reels[1].name == reels[2].name {
            let winAmount = Int(Double(bet) * reels[0].multiplier)
            lastWin = winAmount
            totalWon += winAmount
            score += winAmount
            CurrencyLedger.shared.awardCoins(winAmount, reason: "Slot win: 3x \(reels[0].name)")
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else if reels[0].name == reels[1].name || reels[1].name == reels[2].name {
            let sym = reels[0].name == reels[1].name ? reels[0] : reels[1]
            let winAmount = Int(Double(bet) * sym.multiplier * 0.3)
            lastWin = winAmount
            totalWon += winAmount
            score += winAmount
            CurrencyLedger.shared.awardCoins(winAmount, reason: "Slot partial: 2x \(sym.name)")
        } else {
            lastWin = 0
            streakMultiplier = 1.0
        }
    }

    func endSession() {
        phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward * spins) * streakMultiplier)
        return GameReward(xp: max(1, xp), coins: 0, gems: 0, badgeUnlocked: totalWon > 5000 ? "Jackpot Master" : nil)
    }
}
