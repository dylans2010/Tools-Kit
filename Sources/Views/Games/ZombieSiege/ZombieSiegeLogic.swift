import Foundation

final class ZombieSiegeLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "zombie_siege"
    let baseXPReward = 25; let winXPBonus = 20; let baseCoinReward = 15; let winCoinBonus = 10

    enum GamePhase { case lobby, playing, results }
    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var wave = 0; @Published var totalWaves = 10; @Published var won = false
    @Published var barricadeHP = 100; @Published var maxBarricadeHP = 100
    @Published var enemies: [WaveEnemy] = []; @Published var totalKills = 0
    @Published var consecutiveKills = 0; @Published var bestKillStreak = 0
    @Published var headshots = 0

    struct WaveEnemy: Identifiable {
        let id = UUID(); var hp: Int; var damage: Int; var points: Int; var name: String
    }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; totalWaves = 10 + difficulty * 3
        barricadeHP = 100 + difficulty * 20; maxBarricadeHP = barricadeHP
        wave = 0; score = 0; totalKills = 0; won = false
        consecutiveKills = 0; bestKillStreak = 0; streakMultiplier = 1.0
        phase = .playing; spawnWave()
    }

    func spawnWave() {
        wave += 1
        let count = 2 + wave / 2 + difficulty
        enemies = (0..<count).map { _ in
            WaveEnemy(hp: 1 + wave / 3, damage: 5 + difficulty * 3, points: 40 + wave * 10, name: "Enemy")
        }
    }

    func attack(_ enemy: WaveEnemy) {
        guard let idx = enemies.firstIndex(where: { $0.id == enemy.id }) else { return }
        enemies[idx].hp -= 1
        if enemies[idx].hp <= 0 {
            let pts = enemies[idx].points
            enemies.remove(at: idx); totalKills += 1; consecutiveKills += 1
            bestKillStreak = max(bestKillStreak, consecutiveKills)
            score += Int(Double(pts) * streakMultiplier)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            if enemies.isEmpty {
                if wave >= totalWaves { won = true; phase = .results }
                else { spawnWave() }
            }
        }
    }

    func endTurn() {
        let dmg = enemies.reduce(0) { $0 + $1.damage }
        barricadeHP -= dmg; consecutiveKills = 0
        streakMultiplier = max(1.0, streakMultiplier - 0.1)
        if barricadeHP <= 0 { barricadeHP = 0; won = false; phase = .results }
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if totalKills >= 25 { badge = "Zombie Siege Champion" }
        if bestKillStreak >= 8 { badge = badge ?? "Streak Hunter" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
