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
    ]

    @Published var rotation: Double = 0
    @Published var isSpinning = false
    @Published var resultSlice: WheelSlice?
    @Published var totalWon = 0
    @Published var spins = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var score = 0

    let spinCost = 25

    enum GamePhase { case lobby, playing, results }

    func startGame() { totalWon = 0; spins = 0; score = 0; resultSlice = nil; phase = .playing }

    func spin() {
        guard !isSpinning else { return }
        do { try CurrencyLedger.shared.spendCoins(spinCost) } catch { return }
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
            let prize = self.slices[winIdx].prize
            if prize > 0 {
                self.totalWon += prize; self.score += prize
                CurrencyLedger.shared.awardCoins(prize, reason: "Wheel spin win")
                self.streakMultiplier = min(3.0, self.streakMultiplier + 0.1)
            } else { self.streakMultiplier = 1.0 }
        }
    }

    func endSession() { phase = .results }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward * spins) * streakMultiplier)
        return GameReward(xp: max(1, xp), coins: 0, gems: 0, badgeUnlocked: totalWon >= 1000 ? "Wheel Champion" : nil)
    }
}
