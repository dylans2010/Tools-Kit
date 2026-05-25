import Foundation

class TowerDefenseXLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "tower_defense_x"
    let baseXPReward = 100
    let winXPBonus = 80
    let baseCoinReward = 50
    let winCoinBonus = 0

    @Published var gold = 100
    @Published var health = 20
    @Published var towers: [(Int, Int)] = []

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: Int(Double(baseCoinReward) * streakMultiplier), gems: 0, badgeUnlocked: nil)
    }

    func placeTower(at: (Int, Int)) {
        if gold >= 50 {
            gold -= 50
            towers.append(at)
        }
    }
}
