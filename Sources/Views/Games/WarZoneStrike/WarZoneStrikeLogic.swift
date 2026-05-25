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

    enum GamePhase { case lobby, playing, results }

    private var timer: AnyCancellable?

    func startGame() {
        score = 0
        lives = 5
        currentWave = 0
        gameOver = false
        phase = .playing
        nextWave()
    }

    private func nextWave() {
        guard currentWave < WarZoneMapModel.waves.count else {
            endGame(won: true)
            return
        }
        let waveDef = WarZoneMapModel.waves[currentWave]
        enemies = waveDef.spawnEnemies()
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
            enemies[i].position += enemies[i].speed * 0.05
        }
        let escaped = enemies.filter { $0.position >= 10.0 }
        lives -= escaped.count
        enemies.removeAll { $0.position >= 10.0 }
        if lives <= 0 { endGame(won: false) }
        if enemies.isEmpty && !gameOver {
            timer?.cancel()
            currentWave += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.nextWave()
            }
        }
    }

    func tapEnemy(_ enemy: WaveEnemy) {
        guard let idx = enemies.firstIndex(where: { $0.id == enemy.id }) else { return }
        enemies[idx].health -= 1
        if enemies[idx].health <= 0 {
            score += enemies[idx].points
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            enemies.remove(at: idx)
        }
    }

    private func endGame(won: Bool) {
        gameOver = true
        timer?.cancel()
        phase = .results
    }

    func finalReward() -> GameReward {
        calculateFinalReward(won: currentWave >= 10, score: score, streakMultiplier: streakMultiplier)
    }

    deinit { timer?.cancel() }
}
