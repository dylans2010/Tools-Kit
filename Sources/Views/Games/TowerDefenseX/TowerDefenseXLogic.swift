import Foundation

struct TDEnemy: Identifiable {
    let id = UUID()
    var hp: Int
    let maxHP: Int
    var pathIndex: Int = 0
    var reward: Int
    var isBoss: Bool = false
}

struct TDTower: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
    var damage: Int
    var range: Int
    var level: Int = 1
    let cost: Int
    var towerType: TowerType = .basic

    enum TowerType: String, CaseIterable {
        case basic, sniper, splash, slow
        var icon: String {
            switch self {
            case .basic: return "house.fill"
            case .sniper: return "scope"
            case .splash: return "sun.max.fill"
            case .slow: return "snow"
            }
        }
        var cost: Int {
            switch self {
            case .basic: return 50
            case .sniper: return 100
            case .splash: return 75
            case .slow: return 60
            }
        }
    }

    var upgradeCost: Int { cost * level }
    var maxLevel: Int { 5 }
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
    @Published var towersBuilt: Int = 0
    @Published var score = 0
    @Published var gameOver = false
    @Published var won = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var waveInProgress = false
    @Published var difficulty = 0
    @Published var totalKills = 0
    @Published var bossesKilled = 0
    @Published var towersPlaced = 0
    @Published var totalUpgrades = 0
    @Published var selectedTowerType: TDTower.TowerType = .basic
    @Published var totalWaves = 10

    private var gameTimer: Timer?

    enum GamePhase { case lobby, playing, results }

    private var towerCost: Int {
        switch selectedTowerType {
        case .basic: return 50
        case .sniper: return 100
        case .splash: return 75
        case .slow: return 60
        }
    }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        towers = []; enemies = []; wave = 0; lives = 20 - difficulty * 3
        gold = 200 + difficulty * 50; score = 0
        gameOver = false; won = false; waveInProgress = false
        totalKills = 0; bossesKilled = 0; towersPlaced = 0; totalUpgrades = 0
        totalWaves = 10 + difficulty * 5
        phase = .playing
    }

    func placeTower(row: Int, col: Int) {
        let cost = towerCost
        guard gold >= cost, !path.contains(where: { $0.row == row && $0.col == col }) else { return }
        guard !towers.contains(where: { $0.row == row && $0.col == col }) else { return }
        let (dmg, range): (Int, Int) = {
            switch selectedTowerType {
            case .basic: return (10, 2)
            case .sniper: return (25, 4)
            case .splash: return (8, 2)
            case .slow: return (5, 3)
            }
        }()
        towers.append(TDTower(row: row, col: col, damage: dmg, range: range, cost: cost, towerType: selectedTowerType))
        gold -= cost; towersPlaced += 1
    }

    func upgradeTower(_ towerId: UUID) {
        guard let idx = towers.firstIndex(where: { $0.id == towerId }), towers[idx].level < towers[idx].maxLevel else { return }
        let cost = towers[idx].upgradeCost
        guard gold >= cost else { return }
        gold -= cost
        towers[idx].level += 1
        towers[idx].damage += 5
        towers[idx].range += towers[idx].level % 2 == 0 ? 1 : 0
        totalUpgrades += 1
    }

    func sellTower(_ towerId: UUID) {
        guard let idx = towers.firstIndex(where: { $0.id == towerId }) else { return }
        let refund = towers[idx].cost * towers[idx].level / 2
        gold += refund
        towers.remove(at: idx)
    }

    func startWave() {
        guard !waveInProgress, wave < totalWaves else { return }
        wave += 1; waveInProgress = true
        let enemyCount = wave * 3 + difficulty * 2
        let baseHP = 20 + wave * 15 + difficulty * 10
        let isBossWave = wave % 5 == 0
        for i in 0..<enemyCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8) { [weak self] in
                guard let self = self, !self.gameOver else { return }
                let isBoss = isBossWave && i == enemyCount - 1
                let hp = isBoss ? baseHP * 5 : baseHP
                let reward = (10 + self.wave * 2) * (isBoss ? 5 : 1)
                self.enemies.append(TDEnemy(hp: hp, maxHP: hp, reward: reward, isBoss: isBoss))
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
                enemies[i].hp = 0; lives -= enemies[i].isBoss ? 3 : 1
                if lives <= 0 { endGame(won: false); return }
            }
        }
        for tower in towers {
            switch tower.towerType {
            case .splash:
                let targets = enemies.indices.filter { enemies[$0].hp > 0 && enemies[$0].pathIndex < path.count && distance(tower, path[enemies[$0].pathIndex]) <= tower.range }
                for idx in targets.prefix(3) {
                    enemies[idx].hp -= tower.damage
                    if enemies[idx].hp <= 0 { handleKill(idx) }
                }
            default:
                if let idx = enemies.firstIndex(where: { $0.hp > 0 && $0.pathIndex < path.count && distance(tower, path[$0.pathIndex]) <= tower.range }) {
                    enemies[idx].hp -= tower.damage
                    if enemies[idx].hp <= 0 { handleKill(idx) }
                }
            }
        }
        enemies.removeAll { $0.hp <= 0 && $0.pathIndex >= path.count }
        if enemies.allSatisfy({ $0.hp <= 0 }) && waveInProgress {
            waveInProgress = false; gameTimer?.invalidate()
            score += wave * 20
            streakMultiplier = min(3.0, streakMultiplier + 0.05)
            if wave >= totalWaves { endGame(won: true) }
        }
    }

    private func handleKill(_ idx: Int) {
        gold += enemies[idx].reward; score += enemies[idx].reward; totalKills += 1
        if enemies[idx].isBoss { bossesKilled += 1; score += 200 }
    }

    private func distance(_ tower: TDTower, _ pos: (row: Int, col: Int)) -> Int {
        abs(tower.row - pos.row) + abs(tower.col - pos.col)
    }

    private func endGame(won: Bool) {
        gameTimer?.invalidate(); gameOver = true; self.won = won
        if won { score += 200 + difficulty * 100; streakMultiplier = min(3.0, streakMultiplier + 0.15) }
        else { streakMultiplier = max(1.0, streakMultiplier - 0.1) }
        phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let coins = baseCoinReward + (won ? winCoinBonus : 0)
        let diffBonus = difficulty * 25
        var badge: String?
        if won { badge = "Tower Master" }
        if won && lives >= 15 { badge = badge ?? "Perfect Defense" }
        if bossesKilled >= 3 { badge = badge ?? "Boss Slayer" }
        if totalKills >= 100 { badge = badge ?? "Mass Destroyer" }
        if won && difficulty >= 2 { badge = badge ?? "Tower Legend" }
        let gems = won ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: coins, gems: gems, badgeUnlocked: badge)
    }

    deinit { gameTimer?.invalidate() }
}
