import Foundation

class BlackjackProLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "blackjack_pro"
    let baseXPReward = 40
    let winXPBonus = 60
    let baseCoinReward = 0
    let winCoinBonus = 0

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier)
        return GameReward(xp: xp, coins: score, gems: 0, badgeUnlocked: nil)
    }

    func score(_ hand: [CardDeckModel.Card]) -> Int {
        var s = hand.map { $0.rank.value }.reduce(0, +)
        var aces = hand.filter { $0.rank == .ace }.count
        while s > 21 && aces > 0 { s -= 10; aces -= 1 }
        return s
    }
}
