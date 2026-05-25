import Foundation

final class NavalCombatLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "naval_combat"
    let baseXPReward = 25; let winXPBonus = 25; let baseCoinReward = 15; let winCoinBonus = 15

    enum GamePhase { case lobby, playing, results }
    enum CellState { case unknown, miss, hit, sunk }

    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var gridSize = 8; @Published var grid: [[CellState]] = []
    @Published var ships: [[Bool]] = []; @Published var shotsRemaining = 40
    @Published var hits = 0; @Published var misses = 0; @Published var shipsSunk = 0; @Published var totalShips = 0
    @Published var won = false; @Published var consecutiveHits = 0; @Published var bestStreak = 0

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; gridSize = 8 + difficulty * 2
        shotsRemaining = 40 + difficulty * 10; score = 0; hits = 0; misses = 0; shipsSunk = 0
        consecutiveHits = 0; bestStreak = 0; streakMultiplier = 1.0; won = false
        grid = Array(repeating: Array(repeating: CellState.unknown, count: gridSize), count: gridSize)
        ships = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        placeShips(); phase = .playing
    }

    private func placeShips() {
        let sizes = difficulty == 0 ? [3, 3, 2, 2] : (difficulty == 1 ? [4, 3, 3, 2, 2] : [5, 4, 3, 3, 2, 2])
        totalShips = sizes.count
        for size in sizes {
            var placed = false
            for _ in 0..<200 {
                let horiz = Bool.random()
                let r = Int.random(in: 0..<gridSize); let c = Int.random(in: 0..<gridSize)
                if canPlace(r: r, c: c, size: size, horiz: horiz) {
                    for i in 0..<size { ships[r + (horiz ? 0 : i)][c + (horiz ? i : 0)] = true }
                    placed = true; break
                }
            }
            if !placed { break }
        }
    }

    private func canPlace(r: Int, c: Int, size: Int, horiz: Bool) -> Bool {
        for i in 0..<size {
            let nr = r + (horiz ? 0 : i); let nc = c + (horiz ? i : 0)
            if nr >= gridSize || nc >= gridSize || ships[nr][nc] { return false }
        }
        return true
    }

    func fireAt(row: Int, col: Int) {
        guard row < gridSize, col < gridSize, grid[row][col] == .unknown, shotsRemaining > 0 else { return }
        shotsRemaining -= 1
        if ships[row][col] {
            grid[row][col] = .hit; hits += 1; consecutiveHits += 1
            bestStreak = max(bestStreak, consecutiveHits)
            score += Int(Double(50 + difficulty * 20) * streakMultiplier)
            streakMultiplier = min(3.0, streakMultiplier + 0.15)
        } else {
            grid[row][col] = .miss; misses += 1; consecutiveHits = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.05)
        }
        let totalShipCells = ships.flatMap { $0 }.filter { $0 }.count
        let totalHits = grid.flatMap { $0 }.filter { $0 == .hit }.count
        if totalHits >= totalShipCells { won = true; phase = .results }
        else if shotsRemaining <= 0 { won = false; phase = .results }
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if won && misses <= 5 { badge = "Sharpshooter" }
        if bestStreak >= 5 { badge = badge ?? "Streak Torpedo" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
