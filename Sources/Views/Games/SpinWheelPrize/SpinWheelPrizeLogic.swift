import Foundation

class SpinWheelPrizeLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "spin_wheel_prize"
    let baseXPReward = 20
    let winXPBonus = 0
    let baseCoinReward = 0
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        return GameReward(xp: Int(Double(baseXPReward) * streakMultiplier), coins: score, gems: score > 1000 ? 1 : 0, badgeUnlocked: nil)
    }
}
