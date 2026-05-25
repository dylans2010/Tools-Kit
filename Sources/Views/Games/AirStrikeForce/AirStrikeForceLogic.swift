import Foundation

final class AirStrikeForceLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "air_strike_force"
    let baseXPReward = 25; let winXPBonus = 20; let baseCoinReward = 15; let winCoinBonus = 10

    enum GamePhase { case lobby, playing, results }
    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var wave = 0; @Published var totalWaves = 10
    @Published var shields = 3; @Published var missiles = 15
    @Published var enemies: [Aircraft] = []; @Published var kills = 0
    @Published var won = false; @Published var consecutiveHits = 0; @Published var bestStreak = 0

    struct Aircraft: Identifiable {
        let id = UUID(); var hp: Int; var speed: Int; var points: Int; var name: String
    }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; totalWaves = 10 + difficulty * 3
        shields = 3 + difficulty; missiles = 15 + difficulty * 5
        wave = 0; score = 0; kills = 0; won = false; consecutiveHits = 0; bestStreak = 0
        streakMultiplier = 1.0; phase = .playing; nextWave()
    }

    func nextWave() {
        wave += 1
        let types = [("Fighter", 1, 3, 30), ("Bomber", 2, 1, 50), ("Ace", 3, 2, 80)]
        let count = 2 + wave / 2 + difficulty
        enemies = (0..<count).map { _ in
            let t = types.randomElement()!
            return Aircraft(hp: t.1 + difficulty, speed: t.2, points: t.3 + wave * 5, name: t.0)
        }
    }

    func fireMissile(at target: Aircraft) {
        guard missiles > 0, let idx = enemies.firstIndex(where: { $0.id == target.id }) else { return }
        missiles -= 1; enemies[idx].hp -= 1
        if enemies[idx].hp <= 0 {
            let pts = enemies[idx].points
            enemies.remove(at: idx); kills += 1; consecutiveHits += 1
            bestStreak = max(bestStreak, consecutiveHits)
            score += Int(Double(pts) * streakMultiplier)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            if enemies.isEmpty {
                if wave >= totalWaves { won = true; phase = .results }
                else { nextWave() }
            }
        }
    }

    func enemyStrike() {
        let damage = enemies.reduce(0) { $0 + $1.speed }
        shields -= min(shields, max(1, damage / 3))
        consecutiveHits = 0; streakMultiplier = max(1.0, streakMultiplier - 0.1)
        if shields <= 0 { won = false; phase = .results }
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if kills >= 25 { badge = "Sky Ace" }
        if bestStreak >= 8 { badge = badge ?? "Marksman" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
