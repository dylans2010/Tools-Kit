import Foundation

class BattlefieldCommanderLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "battlefield_commander"
    let baseXPReward = 120
    let winXPBonus = 80
    let baseCoinReward = 60
    let winCoinBonus = 40

    @Published var units: [Int] = [] // Simplified unit positions

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: coins, gems: won && score > 1000 ? 1 : 0, badgeUnlocked: nil)
    }
}
