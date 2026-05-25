import Foundation

struct GameReward {
    let xp: Int
    let coins: Int
    let gems: Int
    let badgeUnlocked: String?
}

protocol GamesRewardable {
    var gameIdentifier: String { get }
    var baseXPReward: Int { get }
    var winXPBonus: Int { get }
    var baseCoinReward: Int { get }
    var winCoinBonus: Int { get }
    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward
}

extension GamesRewardable {
    func calculateFinalReward(won: Bool, score: Int, streakMultiplier: Double) -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + (score / 20)
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: 0, badgeUnlocked: nil)
    }
}

enum BCUnitType: String, CaseIterable {
    case infantry, tank, artillery, scout, medic
    var attack: Int {
        switch self { case .infantry: return 3; case .tank: return 6; case .artillery: return 8; case .scout: return 2; case .medic: return 1 }
    }
    var defense: Int {
        switch self { case .infantry: return 3; case .tank: return 7; case .artillery: return 2; case .scout: return 1; case .medic: return 2 }
    }
    var health: Int {
        switch self { case .infantry: return 10; case .tank: return 20; case .artillery: return 8; case .scout: return 6; case .medic: return 8 }
    }
    var icon: String {
        switch self { case .infantry: return "figure.walk"; case .tank: return "shield.fill"; case .artillery: return "scope"; case .scout: return "binoculars.fill"; case .medic: return "cross.fill" }
    }
}

struct BCUnit: Identifiable, Equatable {
    let id = UUID()
    let type: BCUnitType
    var health: Int
    var isPlayer: Bool
    var row: Int
    var col: Int

    init(type: BCUnitType, isPlayer: Bool, row: Int, col: Int) {
        self.type = type
        self.health = type.health
        self.isPlayer = isPlayer
        self.row = row
        self.col = col
    }
}

final class BattlefieldCommanderLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "battlefield_commander"
    let baseXPReward = 120
    let winXPBonus = 80
    let baseCoinReward = 60
    let winCoinBonus = 40

    let gridSize = 10
    @Published var playerUnits: [BCUnit] = []
    @Published var enemyUnits: [BCUnit] = []
    @Published var selectedUnit: BCUnit?
    @Published var isPlayerTurn = true
    @Published var gameOver = false
    @Published var playerWon = false
    @Published var score = 0
    @Published var turnCount = 0
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0

    enum GamePhase { case lobby, placement, playing, results }

    func startGame() {
        playerUnits = []
        enemyUnits = []
        score = 0
        turnCount = 0
        isPlayerTurn = true
        gameOver = false
        playerWon = false

        let playerTypes: [BCUnitType] = [.infantry, .infantry, .tank, .artillery, .scout, .medic]
        for (i, type) in playerTypes.enumerated() {
            playerUnits.append(BCUnit(type: type, isPlayer: true, row: gridSize - 1 - (i / 3), col: (i % 3) * 3 + 1))
        }
        let enemyTypes: [BCUnitType] = [.infantry, .infantry, .tank, .artillery, .scout, .medic]
        for (i, type) in enemyTypes.enumerated() {
            enemyUnits.append(BCUnit(type: type, isPlayer: false, row: i / 3, col: (i % 3) * 3 + 2))
        }
        phase = .playing
    }

    func selectUnit(_ unit: BCUnit) {
        guard isPlayerTurn, unit.isPlayer, !gameOver else { return }
        selectedUnit = unit
    }

    func moveUnit(to row: Int, col: Int) {
        guard isPlayerTurn, var unit = selectedUnit, !gameOver else { return }
        let dr = abs(row - unit.row)
        let dc = abs(col - unit.col)
        guard dr + dc <= 2 else { return }

        if let enemyIdx = enemyUnits.firstIndex(where: { $0.row == row && $0.col == col }) {
            let damage = max(1, unit.type.attack - enemyUnits[enemyIdx].type.defense / 2)
            enemyUnits[enemyIdx].health -= damage
            score += damage * 10
            if enemyUnits[enemyIdx].health <= 0 {
                enemyUnits.remove(at: enemyIdx)
                score += 50
            }
        } else if playerUnits.first(where: { $0.row == row && $0.col == col }) == nil {
            if let idx = playerUnits.firstIndex(where: { $0.id == unit.id }) {
                playerUnits[idx].row = row
                playerUnits[idx].col = col
                unit = playerUnits[idx]
            }
        }

        selectedUnit = nil
        turnCount += 1
        checkWinCondition()
        if !gameOver {
            isPlayerTurn = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.executeEnemyTurn()
            }
        }
    }

    private func executeEnemyTurn() {
        guard !gameOver else { return }
        for i in enemyUnits.indices {
            guard i < enemyUnits.count else { break }
            if let closest = playerUnits.min(by: { distanceTo($0, from: enemyUnits[i]) < distanceTo($1, from: enemyUnits[i]) }) {
                let dist = distanceTo(closest, from: enemyUnits[i])
                if dist <= 2 {
                    if let pIdx = playerUnits.firstIndex(where: { $0.id == closest.id }) {
                        let damage = max(1, enemyUnits[i].type.attack - playerUnits[pIdx].type.defense / 2)
                        playerUnits[pIdx].health -= damage
                        if playerUnits[pIdx].health <= 0 {
                            playerUnits.remove(at: pIdx)
                        }
                    }
                } else {
                    let dr = closest.row > enemyUnits[i].row ? 1 : (closest.row < enemyUnits[i].row ? -1 : 0)
                    let dc = closest.col > enemyUnits[i].col ? 1 : (closest.col < enemyUnits[i].col ? -1 : 0)
                    let newRow = enemyUnits[i].row + dr
                    let newCol = enemyUnits[i].col + dc
                    if newRow >= 0, newRow < gridSize, newCol >= 0, newCol < gridSize,
                       !enemyUnits.contains(where: { $0.row == newRow && $0.col == newCol }),
                       !playerUnits.contains(where: { $0.row == newRow && $0.col == newCol }) {
                        enemyUnits[i].row = newRow
                        enemyUnits[i].col = newCol
                    }
                }
            }
        }
        checkWinCondition()
        isPlayerTurn = true
    }

    private func distanceTo(_ target: BCUnit, from source: BCUnit) -> Int {
        abs(target.row - source.row) + abs(target.col - source.col)
    }

    private func checkWinCondition() {
        if enemyUnits.isEmpty {
            gameOver = true
            playerWon = true
            phase = .results
        } else if playerUnits.isEmpty {
            gameOver = true
            playerWon = false
            phase = .results
        }
    }

    func finalReward() -> GameReward {
        calculateFinalReward(won: playerWon, score: score, streakMultiplier: streakMultiplier)
    }
}
