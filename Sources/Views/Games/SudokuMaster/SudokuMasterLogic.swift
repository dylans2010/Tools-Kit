import Foundation

final class SudokuMasterLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "sudoku_master"
    let baseXPReward = 90
    let winXPBonus = 60
    let baseCoinReward = 45
    let winCoinBonus = 0

    @Published var puzzle: [[Int]] = []
    @Published var solution: [[Int]] = []
    @Published var playerGrid: [[Int]] = []
    @Published var isOriginal: [[Bool]] = []
    @Published var selectedCell: (row: Int, col: Int)?
    @Published var difficulty = 0
    @Published var score = 0
    @Published var hintsUsed = 0
    @Published var gameOver = false
    @Published var won = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int) {
        self.difficulty = difficulty
        let generated = SudokuGenerator.generate(difficulty: difficulty)
        puzzle = generated.puzzle; solution = generated.solution
        playerGrid = generated.puzzle
        isOriginal = generated.puzzle.map { $0.map { $0 != 0 } }
        selectedCell = nil; score = 0; hintsUsed = 0; gameOver = false; won = false
        phase = .playing
    }

    func placeNumber(_ num: Int) {
        guard let (r, c) = selectedCell, !isOriginal[r][c] else { return }
        playerGrid[r][c] = num
        if num == solution[r][c] { score += 10; streakMultiplier = min(3.0, streakMultiplier + 0.1) }
        else { streakMultiplier = 1.0 }
        checkCompletion()
    }

    func clearCell() {
        guard let (r, c) = selectedCell, !isOriginal[r][c] else { return }
        playerGrid[r][c] = 0
    }

    func useHint() {
        guard let (r, c) = selectedCell, !isOriginal[r][c], playerGrid[r][c] != solution[r][c] else { return }
        do { try CurrencyLedger.shared.spendCoins(25) } catch { return }
        playerGrid[r][c] = solution[r][c]; hintsUsed += 1; score += 5
        checkCompletion()
    }

    private func checkCompletion() {
        if playerGrid == solution { gameOver = true; won = true; score += difficulty == 2 ? 200 : (difficulty == 1 ? 100 : 50); phase = .results }
    }

    func finalReward() -> GameReward {
        let bonus = difficulty == 2 ? winXPBonus : 0
        let xp = Int(Double(baseXPReward + bonus) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier)
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: 0, badgeUnlocked: won && difficulty == 2 ? "Sudoku Grand Master" : nil)
    }
}
