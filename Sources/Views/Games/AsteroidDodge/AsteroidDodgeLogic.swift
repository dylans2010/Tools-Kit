import Foundation

struct Asteroid: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let size: Double
    var speed: Double
}

struct PowerUp: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let type: PowerUpType
    enum PowerUpType: String { case shield, slowmo, coin, magnet }
}

final class AsteroidDodgeLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "asteroid_dodge"
    let baseXPReward = 40
    let winXPBonus = 0
    let baseCoinReward = 20
    let winCoinBonus = 0

    @Published var playerX: Double = 0.5
    @Published var asteroids: [Asteroid] = []
    @Published var powerUps: [PowerUp] = []
    @Published var score = 0
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var difficulty = 0
    @Published var shieldActive = false
    @Published var slowmoActive = false
    @Published var coinsCollected = 0
    @Published var nearMisses = 0
    @Published var survivalTime: Double = 0

    private var timer: Timer?
    private var spawnTimer: Timer?
    private var powerUpTimer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        playerX = 0.5; asteroids = []; powerUps = []; score = 0; gameOver = false
        shieldActive = false; slowmoActive = false; coinsCollected = 0; nearMisses = 0; survivalTime = 0
        phase = .playing; startTimers()
    }

    private func startTimers() {
        timer?.invalidate(); spawnTimer?.invalidate(); powerUpTimer?.invalidate()
        let speedFactor = slowmoActive ? 2.0 : 1.0
        timer = Timer.scheduledTimer(withTimeInterval: 0.033 * speedFactor, repeats: true) { [weak self] _ in self?.update() }
        let spawnRate = max(0.3, 0.8 - Double(difficulty) * 0.15)
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnRate, repeats: true) { [weak self] _ in self?.spawnAsteroid() }
        powerUpTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in self?.spawnPowerUp() }
    }

    func movePlayer(to x: Double) { playerX = min(1, max(0, x)) }

    private func spawnAsteroid() {
        let baseSpeed = 0.008 + Double(difficulty) * 0.003 + Double(score) * 0.00001
        let a = Asteroid(x: Double.random(in: 0.05...0.95), y: 0,
                         size: Double.random(in: 20...50),
                         speed: Double.random(in: baseSpeed...(baseSpeed * 2)))
        asteroids.append(a)
    }

    private func spawnPowerUp() {
        guard !gameOver else { return }
        let types: [PowerUp.PowerUpType] = [.shield, .slowmo, .coin, .magnet]
        let pu = PowerUp(x: Double.random(in: 0.1...0.9), y: 0, type: types.randomElement()!)
        powerUps.append(pu)
    }

    private func update() {
        guard !gameOver else { return }
        score += 1
        survivalTime += 0.033
        let speedMult = slowmoActive ? 0.5 : 1.0
        for i in asteroids.indices { asteroids[i].y += asteroids[i].speed * speedMult }
        for i in powerUps.indices { powerUps[i].y += 0.01 }

        let playerY = 0.85; let playerSize = 30.0
        for pu in powerUps {
            let dx = abs(pu.x - playerX) * 400; let dy = abs(pu.y - playerY) * 800
            if dx < 40 && dy < 40 {
                switch pu.type {
                case .shield: shieldActive = true; DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in self?.shieldActive = false }
                case .slowmo: slowmoActive = true; DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in self?.slowmoActive = false }
                case .coin: coinsCollected += 1; score += 50
                case .magnet: score += 25
                }
                powerUps.removeAll { $0.id == pu.id }
            }
        }

        for a in asteroids {
            let dx = abs(a.x - playerX) * 400; let dy = abs(a.y - playerY) * 800
            if dx < (a.size + playerSize) / 2 && dy < (a.size + playerSize) / 2 {
                if shieldActive {
                    shieldActive = false; score += 100; asteroids.removeAll { $0.id == a.id }
                } else {
                    gameOver = true; timer?.invalidate(); spawnTimer?.invalidate(); powerUpTimer?.invalidate(); phase = .results; return
                }
            }
            let nearDist = (a.size + playerSize) * 0.8
            if dx < nearDist && dy < nearDist && dx >= (a.size + playerSize) / 2 {
                nearMisses += 1; score += 5
            }
        }
        asteroids.removeAll { $0.y > 1.1 }
        powerUps.removeAll { $0.y > 1.1 }
        streakMultiplier = min(3.0, 1.0 + Double(score) / 500.0)
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 20) + coinsCollected * 5
        let diffBonus = difficulty * 15
        var badge: String?
        if score >= 1000 { badge = "Space Dodger" }
        if score >= 3000 { badge = "Asteroid Ace" }
        if nearMisses >= 50 { badge = badge ?? "Daredevil" }
        if survivalTime >= 120 { badge = badge ?? "Survivor" }
        let gems = score >= 2000 && difficulty >= 1 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }

    deinit { timer?.invalidate(); spawnTimer?.invalidate(); powerUpTimer?.invalidate() }
}
