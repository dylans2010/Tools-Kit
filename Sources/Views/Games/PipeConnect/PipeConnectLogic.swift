import Foundation

final class PipeConnectLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "pipe_connect"
    let baseXPReward = 25; let winXPBonus = 20; let baseCoinReward = 15; let winCoinBonus = 10

    enum GamePhase { case lobby, playing, results }
    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var won = false; @Published var level = 1; @Published var totalLevels = 8
    @Published var gridSize = 4; @Published var grid: [[Int]] = []; @Published var solution: [[Int]] = []
    @Published var moves = 0; @Published var hints = 3
    @Published var consecutiveSolves = 0; @Published var bestStreak = 0; @Published var hintsUsed = 0

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty; gridSize = 4 + difficulty
        totalLevels = 8 + difficulty * 3; hints = 3 + difficulty
        level = 0; score = 0; moves = 0; hintsUsed = 0
        consecutiveSolves = 0; bestStreak = 0; streakMultiplier = 1.0; won = false
        phase = .playing; generatePuzzle()
    }

    func generatePuzzle() {
        level += 1; moves = 0
        solution = (0..<gridSize).map { r in (0..<gridSize).map { c in r * gridSize + c + 1 } }
        var shuffled = solution
        for _ in 0..<(20 + level * 5 + difficulty * 10) {
            let r1 = Int.random(in: 0..<gridSize); let c1 = Int.random(in: 0..<gridSize)
            let r2 = Int.random(in: 0..<gridSize); let c2 = Int.random(in: 0..<gridSize)
            let tmp = shuffled[r1][c1]; shuffled[r1][c1] = shuffled[r2][c2]; shuffled[r2][c2] = tmp
        }
        grid = shuffled
    }

    func selectCell(row: Int, col: Int) {
        guard row < gridSize, col < gridSize else { return }
        moves += 1
        let correctVal = solution[row][col]
        if grid[row][col] != correctVal {
            if let cr = grid.firstIndex(where: { $0.contains(correctVal) }),
               let cc = grid[cr].firstIndex(of: correctVal) {
                let tmp = grid[row][col]; grid[row][col] = grid[cr][cc]; grid[cr][cc] = tmp
            }
        }
        checkSolved()
    }

    func useHint() {
        guard hints > 0 else { return }
        hints -= 1; hintsUsed += 1
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if grid[r][c] != solution[r][c] { grid[r][c] = solution[r][c]; checkSolved(); return }
            }
        }
    }

    private func checkSolved() {
        if grid == solution {
            let bonus = max(0, (gridSize * gridSize * 2 - moves) * 5)
            score += Int(Double(100 + bonus + difficulty * 40) * streakMultiplier)
            consecutiveSolves += 1; bestStreak = max(bestStreak, consecutiveSolves)
            streakMultiplier = min(3.0, streakMultiplier + 0.12)
            if level >= totalLevels { won = true; phase = .results }
            else { generatePuzzle() }
        }
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if won { badge = "Pipe Connect Master" }
        if bestStreak >= 5 { badge = badge ?? "Puzzle Streak" }
        if hintsUsed == 0 && won { badge = badge ?? "No Hints Needed" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
