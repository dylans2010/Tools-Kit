import Foundation

struct MineCell: Equatable {
    var isMine: Bool = false
    var isRevealed: Bool = false
    var isFlagged: Bool = false
    var adjacentMines: Int = 0
}

final class MinesweeperXLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "minesweeper_x"
    let baseXPReward = 80
    let winXPBonus = 50
    let baseCoinReward = 40
    let winCoinBonus = 0

    @Published var grid: [[MineCell]] = []
    @Published var rows = 9
    @Published var cols = 9
    @Published var mineCount = 10
    @Published var gameOver = false
    @Published var won = false
    @Published var flagMode = false
    @Published var revealedCount = 0
    @Published var score = 0
    @Published var firstTap = true
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var difficulty = 0

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int) {
        self.difficulty = difficulty
        switch difficulty {
        case 0: rows = 9; cols = 9; mineCount = 10
        case 1: rows = 16; cols = 16; mineCount = 40
        default: rows = 16; cols = 30; mineCount = 99
        }
        grid = Array(repeating: Array(repeating: MineCell(), count: cols), count: rows)
        gameOver = false; won = false; revealedCount = 0; score = 0; firstTap = true
        phase = .playing
    }

    func tap(row: Int, col: Int) {
        guard !gameOver, row >= 0, row < rows, col >= 0, col < cols else { return }
        if flagMode { grid[row][col].isFlagged.toggle(); return }
        guard !grid[row][col].isFlagged, !grid[row][col].isRevealed else { return }

        if firstTap { placeMines(safeRow: row, safeCol: col); firstTap = false }

        if grid[row][col].isMine { gameOver = true; won = false; revealAllMines(); phase = .results; return }

        reveal(row: row, col: col)
        let totalSafe = rows * cols - mineCount
        if revealedCount >= totalSafe { gameOver = true; won = true; score += difficulty == 2 ? 300 : (difficulty == 1 ? 150 : 80); phase = .results }
    }

    private func placeMines(safeRow: Int, safeCol: Int) {
        var placed = 0
        while placed < mineCount {
            let r = Int.random(in: 0..<rows); let c = Int.random(in: 0..<cols)
            if abs(r - safeRow) <= 1 && abs(c - safeCol) <= 1 { continue }
            if !grid[r][c].isMine { grid[r][c].isMine = true; placed += 1 }
        }
        for r in 0..<rows { for c in 0..<cols { grid[r][c].adjacentMines = countAdjacent(r, c) } }
    }

    private func countAdjacent(_ row: Int, _ col: Int) -> Int {
        var count = 0
        for dr in -1...1 { for dc in -1...1 {
            let nr = row + dr; let nc = col + dc
            if nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr][nc].isMine { count += 1 }
        }}
        return count
    }

    private func reveal(row: Int, col: Int) {
        guard row >= 0, row < rows, col >= 0, col < cols, !grid[row][col].isRevealed, !grid[row][col].isMine else { return }
        grid[row][col].isRevealed = true; revealedCount += 1; score += 5
        if grid[row][col].adjacentMines == 0 {
            for dr in -1...1 { for dc in -1...1 { if dr != 0 || dc != 0 { reveal(row: row + dr, col: col + dc) } } }
        }
    }

    private func revealAllMines() {
        for r in 0..<rows { for c in 0..<cols { if grid[r][c].isMine { grid[r][c].isRevealed = true } } }
    }

    func finalReward() -> GameReward {
        let bonus = won ? winXPBonus + (difficulty == 2 ? 50 : 0) : 0
        let xp = Int(Double(baseXPReward + bonus) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier)
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: 0, badgeUnlocked: won && difficulty == 2 ? "Mine Sweeper Pro" : nil)
    }
}
