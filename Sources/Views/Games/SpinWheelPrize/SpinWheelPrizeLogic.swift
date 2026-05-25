import Foundation

struct WheelSlice: Identifiable {
    let id = UUID()
    let label: String
    let prize: Int
    let color: Int
}

final class SpinWheelPrizeLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "spin_wheel_prize"
    let baseXPReward = 20
    let winXPBonus = 0
    let baseCoinReward = 0
    let winCoinBonus = 0

    let slices: [WheelSlice] = [
        WheelSlice(label: "10", prize: 10, color: 0),
        WheelSlice(label: "50", prize: 50, color: 1),
        WheelSlice(label: "100", prize: 100, color: 2),
        WheelSlice(label: "25", prize: 25, color: 3),
        WheelSlice(label: "500", prize: 500, color: 4),
        WheelSlice(label: "0", prize: 0, color: 5),
        WheelSlice(label: "75", prize: 75, color: 0),
        WheelSlice(label: "200", prize: 200, color: 1),
        WheelSlice(label: "1000", prize: 1000, color: 6),
        WheelSlice(label: "150", prize: 150, color: 3),
    ]

    @Published var rotation: Double = 0
    @Published var isSpinning = false
    @Published var resultSlice: WheelSlice?
    @Published var totalWon = 0
    @Published var spins = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var score = 0
    @Published var consecutiveWins = 0
    @Published var bestConsecutiveWins = 0
    @Published var biggestWin = 0
    @Published var freeSpinsAvailable = 0
    @Published var multiplierActive = false
    @Published var currentMultiplier = 1

    let spinCost = 25

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        totalWon = 0; spins = 0; score = 0; resultSlice = nil; consecutiveWins = 0
        bestConsecutiveWins = 0; biggestWin = 0; freeSpinsAvailable = 0
        multiplierActive = false; currentMultiplier = 1
        phase = .playing
    }

    func activateMultiplier() {
        guard !multiplierActive else { return }
        do { try CurrencyLedger.shared.spendCoins(50) } catch { return }
        multiplierActive = true
        currentMultiplier = 2
    }

    func spin() {
        guard !isSpinning else { return }
        let isFree = freeSpinsAvailable > 0
        if !isFree {
            do { try CurrencyLedger.shared.spendCoins(spinCost) } catch { return }
        } else {
            freeSpinsAvailable -= 1
        }
        isSpinning = true; spins += 1; resultSlice = nil
        let extraRotations = Double.random(in: 3...6) * 360
        let sliceAngle = 360.0 / Double(slices.count)
        let winIdx = Int.random(in: 0..<slices.count)
        let targetAngle = extraRotations + Double(winIdx) * sliceAngle
        rotation += targetAngle
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            self.isSpinning = false
            self.resultSlice = self.slices[winIdx]
            let basePrize = self.slices[winIdx].prize
            let prize = basePrize * self.currentMultiplier
            if prize > 0 {
                self.totalWon += prize; self.score += prize
                self.biggestWin = max(self.biggestWin, prize)
                self.consecutiveWins += 1
                self.bestConsecutiveWins = max(self.bestConsecutiveWins, self.consecutiveWins)
                CurrencyLedger.shared.awardCoins(prize, reason: "Wheel spin win")
                self.streakMultiplier = min(3.0, self.streakMultiplier + 0.1)
                if self.consecutiveWins >= 3 && self.consecutiveWins % 3 == 0 {
                    self.freeSpinsAvailable += 1
                }
            } else {
                self.consecutiveWins = 0
                self.streakMultiplier = max(1.0, self.streakMultiplier - 0.1)
            }
            if self.multiplierActive { self.multiplierActive = false; self.currentMultiplier = 1 }
        }
    }

    func endSession() { phase = .results }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward * spins) * streakMultiplier)
        var badge: String?
        if totalWon >= 1000 { badge = "Wheel Champion" }
        if biggestWin >= 500 { badge = badge ?? "Big Spin" }
        if bestConsecutiveWins >= 5 { badge = badge ?? "Lucky Spinner" }
        if totalWon >= 3000 { badge = badge ?? "Wheel Master" }
        let gems = biggestWin >= 1000 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: 0, gems: gems, badgeUnlocked: badge)
    }
}
