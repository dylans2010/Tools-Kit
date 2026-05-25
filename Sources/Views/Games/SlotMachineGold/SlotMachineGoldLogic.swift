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
    @Published var freeSpins = 0
    @Published var consecutiveWins = 0
    @Published var biggestWin = 0
    @Published var jackpotProgress: Double = 0
    @Published var autoSpinEnabled = false
    @Published var autoSpinsRemaining = 0

    enum GamePhase { case lobby, playing, results }

    let minBet = 10
    let maxBet = 500

    var jackpotAmount: Int {
        let gameLevel = CurrencyLedger.shared.gameStats(for: gameIdentifier).gameLevel
        return 10000 + gameLevel * 1000
    }

    func startGame() {
        totalWon = 0
        spins = 0
        score = 0
        lastWin = 0
        freeSpins = 0
        consecutiveWins = 0
        biggestWin = 0
        jackpotProgress = 0
        autoSpinEnabled = false
        autoSpinsRemaining = 0
        phase = .playing
    }

    func spin() {
        let isFree = freeSpins > 0
        if !isFree {
            let balance = CurrencyLedger.shared.profile.coins
            guard bet <= balance, !isSpinning else { return }
            do { try CurrencyLedger.shared.spendCoins(bet) } catch { return }
        } else {
            freeSpins -= 1
        }

        isSpinning = true
        spins += 1
        jackpotProgress = min(1.0, jackpotProgress + 0.02)

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
                self.resolveOutcome(finalReels, isFree: isFree)
            }
        }
    }

    private func resolveOutcome(_ reels: [SlotSymbol], isFree: Bool) {
        self.reels = reels
        isSpinning = false
        let activeBet = isFree ? bet : bet

        if jackpotProgress >= 1.0 && Bool.random() && Bool.random() {
            let jackpot = jackpotAmount
            lastWin = jackpot
            totalWon += jackpot
            score += jackpot
            biggestWin = max(biggestWin, jackpot)
            CurrencyLedger.shared.awardCoins(jackpot, reason: "JACKPOT!")
            jackpotProgress = 0
            consecutiveWins += 1
            streakMultiplier = min(3.0, streakMultiplier + 0.3)
            return
        }

        if reels[0].name == reels[1].name && reels[1].name == reels[2].name {
            let baseWin = Int(Double(activeBet) * reels[0].multiplier)
            let streakBonus = consecutiveWins >= 3 ? 1.5 : 1.0
            let winAmount = Int(Double(baseWin) * streakBonus)
            lastWin = winAmount
            totalWon += winAmount
            score += winAmount
            biggestWin = max(biggestWin, winAmount)
            CurrencyLedger.shared.awardCoins(winAmount, reason: "Slot win: 3x \(reels[0].name)")
            streakMultiplier = min(3.0, streakMultiplier + 0.15)
            consecutiveWins += 1

            if reels[0].name == "Seven" || reels[0].name == "Diamond" {
                freeSpins += 3
            }
        } else if reels[0].name == reels[1].name || reels[1].name == reels[2].name || reels[0].name == reels[2].name {
            let sym = reels[0].name == reels[1].name ? reels[0] : (reels[1].name == reels[2].name ? reels[1] : reels[0])
            let winAmount = Int(Double(activeBet) * sym.multiplier * 0.3)
            lastWin = winAmount
            totalWon += winAmount
            score += winAmount
            biggestWin = max(biggestWin, winAmount)
            CurrencyLedger.shared.awardCoins(winAmount, reason: "Slot partial: 2x \(sym.name)")
            consecutiveWins += 1
        } else {
            lastWin = 0
            consecutiveWins = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.05)
        }

        if autoSpinEnabled && autoSpinsRemaining > 0 {
            autoSpinsRemaining -= 1
            if autoSpinsRemaining > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.spin()
                }
            } else {
                autoSpinEnabled = false
            }
        }
    }

    func startAutoSpin(count: Int) {
        autoSpinEnabled = true
        autoSpinsRemaining = count
        spin()
    }

    func stopAutoSpin() {
        autoSpinEnabled = false
        autoSpinsRemaining = 0
    }

    func endSession() {
        autoSpinEnabled = false
        phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward * spins) * streakMultiplier)
        var badge: String?
        if totalWon > 5000 { badge = "Jackpot Master" }
        if biggestWin >= jackpotAmount { badge = badge ?? "Jackpot Winner" }
        if consecutiveWins >= 5 { badge = badge ?? "Hot Streak" }
        if spins >= 50 { badge = badge ?? "Slot Veteran" }
        let gems = totalWon >= 10000 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: 0, gems: gems, badgeUnlocked: badge)
    }
}
