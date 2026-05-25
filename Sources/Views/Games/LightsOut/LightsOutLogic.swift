import Foundation

final class LightsOutLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "lights_out"
    let baseXPReward = 25; let winXPBonus = 20; let baseCoinReward = 15; let winCoinBonus = 10

    enum GamePhase { case lobby, playing, results }
    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var gridSize = 5; @Published var grid: [[Bool]] = []; @Published var moves = 0
    @Published var won = false; @Published var level = 1; @Published var totalLevels = 5
    @Published var consecutiveSolves = 0; @Published var bestStreak = 0

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; gridSize = 5 + difficulty
        totalLevels = 5 + difficulty * 3; level = 0; score = 0; moves = 0
        consecutiveSolves = 0; bestStreak = 0; streakMultiplier = 1.0; won = false
        phase = .playing; generateLevel()
    }

    func generateLevel() {
        level += 1; moves = 0
        grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        let toggles = 3 + level + difficulty * 2
        for _ in 0..<toggles {
            let r = Int.random(in: 0..<gridSize); let c = Int.random(in: 0..<gridSize)
            toggleCell(r, c, counting: false)
        }
    }

    func tap(row: Int, col: Int) {
        toggleCell(row, col, counting: true); moves += 1
        if grid.allSatisfy({ $0.allSatisfy({ !$0 }) }) {
            let bonus = max(0, (gridSize * gridSize - moves) * 10)
            score += Int(Double(100 + bonus + difficulty * 50) * streakMultiplier)
            consecutiveSolves += 1; bestStreak = max(bestStreak, consecutiveSolves)
            streakMultiplier = min(3.0, streakMultiplier + 0.15)
            if level >= totalLevels { won = true; phase = .results }
            else { generateLevel() }
        }
    }

    private func toggleCell(_ r: Int, _ c: Int, counting: Bool) {
        let neighbors = [(r,c),(r-1,c),(r+1,c),(r,c-1),(r,c+1)]
        for (nr, nc) in neighbors {
            if nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize {
                grid[nr][nc].toggle()
            }
        }
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if won { badge = "Lights Master" }
        if bestStreak >= 5 { badge = badge ?? "Consecutive Solver" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
