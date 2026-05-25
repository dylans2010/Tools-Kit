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
        let dailyMult = CurrencyLedger.shared.dailyStreakMultiplier()
        let gameBonus = CurrencyLedger.shared.streakBonus(for: gameIdentifier)
        let combinedMult = streakMultiplier * dailyMult * gameBonus
        let gameLevel = CurrencyLedger.shared.gameStats(for: gameIdentifier).gameLevel
        let levelBonus = 1.0 + Double(gameLevel - 1) * 0.02
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * combinedMult * levelBonus) + (score / 10)
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * combinedMult * levelBonus) + (score / 20)
        let gems = gameLevel >= 10 && won ? 1 : 0
        let stat = CurrencyLedger.shared.gameStats(for: gameIdentifier)
        var badge: String?
        if stat.bestStreak >= 10 { badge = "\(gameIdentifier)_streak_master" }
        if stat.gamesPlayed >= 100 { badge = "\(gameIdentifier)_veteran" }
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}

enum BCUnitType: String, CaseIterable {
    case infantry, tank, artillery, scout, medic, sniper
    var attack: Int {
        switch self { case .infantry: return 3; case .tank: return 6; case .artillery: return 8; case .scout: return 2; case .medic: return 1; case .sniper: return 10 }
    }
    var defense: Int {
        switch self { case .infantry: return 3; case .tank: return 7; case .artillery: return 2; case .scout: return 1; case .medic: return 2; case .sniper: return 1 }
    }
    var health: Int {
        switch self { case .infantry: return 10; case .tank: return 20; case .artillery: return 8; case .scout: return 6; case .medic: return 8; case .sniper: return 5 }
    }
    var icon: String {
        switch self { case .infantry: return "figure.walk"; case .tank: return "shield.fill"; case .artillery: return "scope"; case .scout: return "binoculars.fill"; case .medic: return "cross.fill"; case .sniper: return "target" }
    }
    var movementRange: Int {
        switch self { case .infantry: return 2; case .tank: return 2; case .artillery: return 1; case .scout: return 3; case .medic: return 2; case .sniper: return 1 }
    }
    var attackRange: Int {
        switch self { case .infantry: return 1; case .tank: return 2; case .artillery: return 4; case .scout: return 2; case .medic: return 1; case .sniper: return 5 }
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
    @Published var difficulty = 0
    @Published var currentWave = 1
    @Published var totalWaves = 3
    @Published var killCount = 0
    @Published var comboKills = 0
    @Published var turnKills = 0
    @Published var message = ""
    @Published var hintsRemaining = 3

    enum GamePhase { case lobby, placement, playing, results }

    private var difficultyNames = ["Recruit", "Veteran", "Commander"]

    var difficultyName: String { difficultyNames[min(difficulty, difficultyNames.count - 1)] }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        playerUnits = []
        enemyUnits = []
        score = 0
        turnCount = 0
        isPlayerTurn = true
        gameOver = false
        playerWon = false
        currentWave = 1
        killCount = 0
        comboKills = 0
        turnKills = 0
        message = ""
        hintsRemaining = 3 - difficulty
        totalWaves = 2 + difficulty

        let gameLevel = CurrencyLedger.shared.gameStats(for: gameIdentifier).gameLevel
        let hasSniper = gameLevel >= 3
        var playerTypes: [BCUnitType] = [.infantry, .infantry, .tank, .artillery, .scout, .medic]
        if hasSniper { playerTypes.append(.sniper) }

        for (i, type) in playerTypes.enumerated() {
            playerUnits.append(BCUnit(type: type, isPlayer: true, row: gridSize - 1 - (i / 3), col: (i % 3) * 3 + 1))
        }

        spawnEnemyWave()
        phase = .playing
    }

    private func spawnEnemyWave() {
        let baseTypes: [BCUnitType] = [.infantry, .infantry, .tank, .artillery, .scout, .medic]
        let waveExtra = currentWave - 1
        var types = baseTypes
        for _ in 0..<(waveExtra + difficulty) { types.append([BCUnitType.infantry, .tank, .artillery, .scout].randomElement()!) }

        for (i, type) in types.enumerated() {
            let row = i / 3
            let col = (i % 3) * 3 + 2
            guard row < gridSize, col < gridSize else { continue }
            guard !enemyUnits.contains(where: { $0.row == row && $0.col == col }) else { continue }
            var unit = BCUnit(type: type, isPlayer: false, row: row, col: col)
            if difficulty >= 1 { unit.health += currentWave * 2 }
            if difficulty >= 2 { unit.health += currentWave * 3 }
            enemyUnits.append(unit)
        }
        message = "Wave \(currentWave)/\(totalWaves)"
    }

    func useHint() -> (row: Int, col: Int)? {
        guard hintsRemaining > 0, !enemyUnits.isEmpty else { return nil }
        hintsRemaining -= 1
        if let weakest = enemyUnits.min(by: { $0.health < $1.health }) {
            message = "Target the \(weakest.type.rawValue) at (\(weakest.row),\(weakest.col))!"
            return (weakest.row, weakest.col)
        }
        return nil
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
            if currentWave < totalWaves {
                currentWave += 1
                score += 100 * currentWave
                message = "Wave cleared! +\(100 * currentWave) pts"
                streakMultiplier = min(3.0, streakMultiplier + 0.15)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.spawnEnemyWave()
                }
            } else {
                gameOver = true
                playerWon = true
                score += 500 * (difficulty + 1)
                message = "All waves cleared!"
                streakMultiplier = min(3.0, streakMultiplier + 0.2)
                phase = .results
            }
        } else if playerUnits.isEmpty {
            gameOver = true
            playerWon = false
            streakMultiplier = 1.0
            message = "Defeated on wave \(currentWave)"
            phase = .results
        }
    }

    func finalReward() -> GameReward {
        var reward = calculateFinalReward(won: playerWon, score: score, streakMultiplier: streakMultiplier)
        let difficultyBonus = difficulty * 30
        let waveBonus = (currentWave - 1) * 20
        let totalXP = reward.xp + difficultyBonus + waveBonus
        let totalCoins = reward.coins + (playerWon ? difficulty * 20 : 0)
        let gems = playerWon && difficulty >= 2 ? 1 : reward.gems
        var badge = reward.badgeUnlocked
        if playerWon && difficulty >= 2 { badge = "Battlefield Commander" }
        if killCount >= 20 { badge = badge ?? "Warmonger" }
        if turnCount <= 15 && playerWon { badge = badge ?? "Blitz Commander" }
        reward = GameReward(xp: totalXP, coins: totalCoins, gems: gems, badgeUnlocked: badge)
        return reward
    }
}
