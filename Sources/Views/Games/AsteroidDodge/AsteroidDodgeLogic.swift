import Foundation

struct Asteroid: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let size: Double
    var speed: Double
}

final class AsteroidDodgeLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "asteroid_dodge"
    let baseXPReward = 40
    let winXPBonus = 0
    let baseCoinReward = 20
    let winCoinBonus = 0

    @Published var playerX: Double = 0.5
    @Published var asteroids: [Asteroid] = []
    @Published var score = 0
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0

    private var timer: Timer?
    private var spawnTimer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        playerX = 0.5; asteroids = []; score = 0; gameOver = false; phase = .playing
        startTimers()
    }

    private func startTimers() {
        timer?.invalidate(); spawnTimer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in self?.update() }
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in self?.spawnAsteroid() }
    }

    func movePlayer(to x: Double) { playerX = min(1, max(0, x)) }

    private func spawnAsteroid() {
        let a = Asteroid(x: Double.random(in: 0.05...0.95), y: 0, size: Double.random(in: 20...50), speed: Double.random(in: 0.008...0.02))
        asteroids.append(a)
    }

    private func update() {
        guard !gameOver else { return }
        score += 1
        for i in asteroids.indices { asteroids[i].y += asteroids[i].speed }
        let playerY = 0.85; let playerSize = 30.0
        for a in asteroids {
            let dx = abs(a.x - playerX) * 400; let dy = abs(a.y - playerY) * 800
            if dx < (a.size + playerSize) / 2 && dy < (a.size + playerSize) / 2 {
                gameOver = true; timer?.invalidate(); spawnTimer?.invalidate(); phase = .results; return
            }
        }
        asteroids.removeAll { $0.y > 1.1 }
        streakMultiplier = min(3.0, 1.0 + Double(score) / 500.0)
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 20)
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: 0, badgeUnlocked: score >= 1000 ? "Space Dodger" : nil)
    }

    deinit { timer?.invalidate(); spawnTimer?.invalidate() }
}
