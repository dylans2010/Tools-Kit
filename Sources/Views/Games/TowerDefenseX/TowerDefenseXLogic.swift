import Foundation

struct TDEnemy: Identifiable {
    let id = UUID()
    var hp: Int
    let maxHP: Int
    var pathIndex: Int = 0
    var reward: Int
}

struct TDTower: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
    var damage: Int
    var range: Int
    var level: Int = 1
    let cost: Int
}

final class TowerDefenseXLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "tower_defense_x"
    let baseXPReward = 70
    let winXPBonus = 50
    let baseCoinReward = 35
    let winCoinBonus = 20

    let gridSize = 8
    let path: [(row: Int, col: Int)] = [(0,0),(0,1),(0,2),(0,3),(1,3),(2,3),(2,4),(2,5),(2,6),(2,7),(3,7),(4,7),(4,6),(4,5),(4,4),(4,3),(4,2),(5,2),(6,2),(6,3),(6,4),(6,5),(6,6),(6,7),(7,7)]

    @Published var towers: [TDTower] = []
    @Published var enemies: [TDEnemy] = []
    @Published var wave = 0
    @Published var lives = 20
    @Published var gold = 200
    @Published var score = 0
    @Published var gameOver = false
    @Published var won = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var waveInProgress = false

    private var gameTimer: Timer?
    let totalWaves = 10

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        towers = []; enemies = []; wave = 0; lives = 20; gold = 200; score = 0
        gameOver = false; won = false; waveInProgress = false; phase = .playing
    }

    func placeTower(row: Int, col: Int) {
        guard gold >= 50, !path.contains(where: { $0.row == row && $0.col == col }) else { return }
        guard !towers.contains(where: { $0.row == row && $0.col == col }) else { return }
        towers.append(TDTower(row: row, col: col, damage: 10, range: 2, cost: 50))
        gold -= 50
    }

    func startWave() {
        guard !waveInProgress, wave < totalWaves else { return }
        wave += 1; waveInProgress = true
        let enemyCount = wave * 3
        let hp = 20 + wave * 15
        for i in 0..<enemyCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8) { [weak self] in
                guard let self = self, !self.gameOver else { return }
                self.enemies.append(TDEnemy(hp: hp, maxHP: hp, reward: 10 + self.wave * 2))
            }
        }
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard !gameOver else { gameTimer?.invalidate(); return }
        for i in enemies.indices where enemies[i].hp > 0 {
            enemies[i].pathIndex += 1
            if enemies[i].pathIndex >= path.count {
                enemies[i].hp = 0; lives -= 1
                if lives <= 0 { endGame(won: false); return }
            }
        }
        for tower in towers {
            if let idx = enemies.firstIndex(where: { $0.hp > 0 && $0.pathIndex < path.count && distance(tower, path[$0.pathIndex]) <= tower.range }) {
                enemies[idx].hp -= tower.damage
                if enemies[idx].hp <= 0 { gold += enemies[idx].reward; score += enemies[idx].reward }
            }
        }
        enemies.removeAll { $0.hp <= 0 && $0.pathIndex >= path.count }
        if enemies.allSatisfy({ $0.hp <= 0 }) && waveInProgress {
            waveInProgress = false; gameTimer?.invalidate()
            if wave >= totalWaves { endGame(won: true) }
        }
    }

    private func distance(_ tower: TDTower, _ pos: (row: Int, col: Int)) -> Int {
        abs(tower.row - pos.row) + abs(tower.col - pos.col)
    }

    private func endGame(won: Bool) {
        gameTimer?.invalidate(); gameOver = true; self.won = won
        if won { score += 200; streakMultiplier = min(3.0, streakMultiplier + 0.1) }
        else { streakMultiplier = 1.0 }
        phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let coins = baseCoinReward + (won ? winCoinBonus : 0)
        return GameReward(xp: max(1, xp), coins: coins, gems: won ? 1 : 0, badgeUnlocked: won ? "Tower Master" : nil)
    }

    deinit { gameTimer?.invalidate() }
}
