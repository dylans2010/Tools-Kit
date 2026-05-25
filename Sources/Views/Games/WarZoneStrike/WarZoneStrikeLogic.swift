import Foundation
import Combine

final class WarZoneStrikeLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "warzone_strike"
    let baseXPReward = 80
    let winXPBonus = 0
    let baseCoinReward = 45
    let winCoinBonus = 0

    @Published var enemies: [WaveEnemy] = []
    @Published var currentWave = 0
    @Published var score = 0
    @Published var lives = 5
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var difficulty = 0
    @Published var totalKills = 0
    @Published var killStreak: Int = 0
    @Published var bestKillStreak: Int = 0
    @Published var bossesKilled = 0
    @Published var consecutiveKills = 0
    @Published var bestConsecutiveKills = 0
    @Published var powerUpActive = false
    @Published var powerUpType = ""
    @Published var totalWaves = 10

    enum GamePhase { case lobby, playing, results }

    private var timer: AnyCancellable?

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        score = 0; lives = 5 - min(difficulty, 2); currentWave = 0; gameOver = false
        totalKills = 0; bossesKilled = 0; consecutiveKills = 0; bestConsecutiveKills = 0
        powerUpActive = false; powerUpType = ""
        totalWaves = min(WarZoneMapModel.waves.count, 10 + difficulty * 3)
        phase = .playing; nextWave()
    }

    private func nextWave() {
        guard currentWave < totalWaves, currentWave < WarZoneMapModel.waves.count else {
            endGame(won: true)
            return
        }
        let waveDef = WarZoneMapModel.waves[currentWave]
        var spawnedEnemies = waveDef.spawnEnemies()
        let healthMultiplier = 1.0 + Double(difficulty) * 0.3
        for i in spawnedEnemies.indices {
            spawnedEnemies[i].health = Int(Double(spawnedEnemies[i].health) * healthMultiplier)
            spawnedEnemies[i].speed *= (1.0 + Double(difficulty) * 0.15)
        }
        enemies = spawnedEnemies
        startWaveTimer()
    }

    private func startWaveTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.updatePositions()
        }
    }

    private func updatePositions() {
        guard !gameOver else { timer?.cancel(); return }
        for i in enemies.indices {
            let speedMult = powerUpActive && powerUpType == "slow" ? 0.5 : 1.0
            enemies[i].position += enemies[i].speed * 0.05 * speedMult
        }
        let escaped = enemies.filter { $0.position >= 10.0 }
        if !escaped.isEmpty {
            lives -= escaped.count
            consecutiveKills = 0
        }
        enemies.removeAll { $0.position >= 10.0 }
        if lives <= 0 { endGame(won: false) }
        if enemies.isEmpty && !gameOver {
            timer?.cancel()
            score += 50 * (currentWave + 1)
            currentWave += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.nextWave()
            }
        }
    }

    func tapEnemy(_ enemy: WaveEnemy) {
        guard let idx = enemies.firstIndex(where: { $0.id == enemy.id }) else { return }
        let dmg = powerUpActive && powerUpType == "damage" ? 2 : 1
        enemies[idx].health -= dmg
        if enemies[idx].health <= 0 {
            let points = enemies[idx].points * (1 + difficulty)
            score += points; totalKills += 1
            consecutiveKills += 1
            bestConsecutiveKills = max(bestConsecutiveKills, consecutiveKills)
            streakMultiplier = min(3.0, streakMultiplier + 0.05)

            if consecutiveKills >= 10 && consecutiveKills % 10 == 0 && !powerUpActive {
                activatePowerUp()
            }

            enemies.remove(at: idx)
        }
    }

    func activatePowerUp() {
        powerUpActive = true
        let types = ["damage", "slow", "heal"]
        powerUpType = types.randomElement()!
        if powerUpType == "heal" { lives = min(lives + 1, 5) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.powerUpActive = false; self?.powerUpType = ""
        }
    }

    private func endGame(won: Bool) {
        gameOver = true; timer?.cancel()
        if won { score += 200 + difficulty * 100; streakMultiplier = min(3.0, streakMultiplier + 0.15) }
        else { streakMultiplier = max(1.0, streakMultiplier - 0.1) }
        phase = .results
    }

    func finalReward() -> GameReward {
        let won = currentWave >= totalWaves
        var reward = calculateFinalReward(won: won, score: score, streakMultiplier: streakMultiplier)
        let diffBonus = difficulty * 25
        var badge: String?
        if won { badge = "War Zone Victor" }
        if totalKills >= 50 { badge = badge ?? "Kill Machine" }
        if bestConsecutiveKills >= 20 { badge = badge ?? "Kill Streak" }
        if won && lives >= 4 { badge = badge ?? "Untouchable" }
        if won && difficulty >= 2 { badge = badge ?? "War Hero" }
        let gems = won && difficulty >= 1 ? 1 : 0
        reward = GameReward(xp: reward.xp + diffBonus, coins: reward.coins, gems: gems, badgeUnlocked: badge)
        return reward
    }

    deinit { timer?.cancel() }
}
