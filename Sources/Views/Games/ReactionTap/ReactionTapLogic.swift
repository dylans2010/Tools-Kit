import Foundation

class ReactionTapLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "reaction_tap"
    let baseXPReward = 40
    let winXPBonus = 0
    let baseCoinReward = 20
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let bonus = score < 200 ? 50 : 0
        return GameReward(xp: Int(Double(baseXPReward + bonus) * streakMultiplier), coins: Int(Double(baseCoinReward) * streakMultiplier), gems: 0, badgeUnlocked: nil)
    }
}
