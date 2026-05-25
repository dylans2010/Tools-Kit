import Foundation

final class TankAssaultLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "tank_assault"
    let baseXPReward = 25; let winXPBonus = 20; let baseCoinReward = 15; let winCoinBonus = 10

    enum GamePhase { case lobby, playing, results }
    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0
    @Published var streakMultiplier: Double = 1.0
    @Published var wave = 0; @Published var totalWaves = 8
    @Published var playerHP = 100; @Published var maxHP = 100
    @Published var ammo = 20; @Published var enemiesAlive: [TankEnemy] = []
    @Published var kills = 0; @Published var shotsFired = 0
    @Published var won = false; @Published var consecutiveKills = 0; @Published var bestKillStreak = 0

    struct TankEnemy: Identifiable {
        let id = UUID(); var hp: Int; var lane: Int; var distance: Double; var damage: Int
    }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        totalWaves = 8 + difficulty * 4; playerHP = 100 + difficulty * 20; maxHP = playerHP
        ammo = 20 + difficulty * 5; wave = 0; score = 0; kills = 0; shotsFired = 0
        consecutiveKills = 0; bestKillStreak = 0; streakMultiplier = 1.0
        won = false; phase = .playing; spawnWave()
    }

    func spawnWave() {
        wave += 1
        let count = 2 + wave / 2 + difficulty
        enemiesAlive = (0..<count).map { _ in
            TankEnemy(hp: 1 + wave / 3 + difficulty, lane: Int.random(in: 0...2),
                      distance: Double.random(in: 0.5...1.0), damage: 5 + difficulty * 3 + wave)
        }
    }

    func shoot(at enemy: TankEnemy) {
        guard ammo > 0, let idx = enemiesAlive.firstIndex(where: { $0.id == enemy.id }) else { return }
        ammo -= 1; shotsFired += 1; enemiesAlive[idx].hp -= 1
        if enemiesAlive[idx].hp <= 0 {
            enemiesAlive.remove(at: idx); kills += 1; consecutiveKills += 1
            bestKillStreak = max(bestKillStreak, consecutiveKills)
            let basePoints = 50 + wave * 10 + difficulty * 20
            score += Int(Double(basePoints) * streakMultiplier)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            if enemiesAlive.isEmpty { advanceOrWin() }
        }
    }

    func advanceOrWin() {
        if wave >= totalWaves { won = true; phase = .results }
        else { spawnWave() }
    }

    func enemyAttack() {
        for e in enemiesAlive { playerHP -= e.damage }
        consecutiveKills = 0; streakMultiplier = max(1.0, streakMultiplier - 0.15)
        if playerHP <= 0 { playerHP = 0; won = false; phase = .results }
    }

    func reload() { ammo += 5 }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if kills >= 30 { badge = "Tank Ace" }
        if bestKillStreak >= 10 { badge = badge ?? "Kill Streak Master" }
        if won && playerHP == maxHP { badge = badge ?? "Untouchable" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
