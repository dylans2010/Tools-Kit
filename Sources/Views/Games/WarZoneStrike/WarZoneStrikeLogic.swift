import Foundation

class WarZoneStrikeLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "warzone_strike"
    let baseXPReward = 80
    let winXPBonus = 0
    let baseCoinReward = 45
    let winCoinBonus = 0

    @Published var wave = 1
    @Published var enemies: [Enemy] = []

    struct Enemy: Identifiable {
        let id = UUID()
        var lane: Int
        var position: Double
    }

    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (score / 10)) * streakMultiplier)
        let coins = Int(Double(baseCoinReward + (score / 20)) * streakMultiplier)
        return GameReward(xp: xp, coins: coins, gems: 0, badgeUnlocked: nil)
    }

    func update() {
        for i in 0..<enemies.count {
            enemies[i].position += 0.01
        }
        if enemies.isEmpty {
            spawnWave()
        }
    }

    private func spawnWave() {
        let config = WarZoneMapModel.defaultProgression[min(wave-1, 9)]
        for _ in 0..<config.enemyCount {
            enemies.append(Enemy(lane: Int.random(in: 0...2), position: 0))
        }
        wave += 1
    }
}
