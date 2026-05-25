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
    @Published var maxHints = 5
    @Published var gameOver = false
    @Published var won = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var mistakes = 0
    @Published var maxMistakes = 5
    @Published var consecutiveCorrect = 0
    @Published var bestConsecutiveCorrect = 0
    @Published var startTime: Date?
    @Published var elapsedTime: Double = 0
    @Published var notesMode = false
    @Published var notes: [[[Bool]]] = []

    private var timer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int) {
        self.difficulty = difficulty
        let generated = SudokuGenerator.generate(difficulty: difficulty)
        puzzle = generated.puzzle; solution = generated.solution
        playerGrid = generated.puzzle
        isOriginal = generated.puzzle.map { $0.map { $0 != 0 } }
        notes = Array(repeating: Array(repeating: Array(repeating: false, count: 9), count: 9), count: 9)
        selectedCell = nil; score = 0; hintsUsed = 0; gameOver = false; won = false
        mistakes = 0; consecutiveCorrect = 0; bestConsecutiveCorrect = 0
        maxHints = difficulty == 0 ? 5 : (difficulty == 1 ? 3 : 1)
        maxMistakes = difficulty == 0 ? 5 : (difficulty == 1 ? 3 : 1)
        let gameLevel = CurrencyLedger.shared.gameStats(for: gameIdentifier).gameLevel
        if gameLevel >= 5 { maxHints += 1 }
        if gameLevel >= 10 { maxMistakes += 1 }
        elapsedTime = 0; startTime = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime, !self.gameOver else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
        phase = .playing
    }

    func placeNumber(_ num: Int) {
        guard let (r, c) = selectedCell, !isOriginal[r][c] else { return }
        if notesMode {
            notes[r][c][num - 1].toggle()
            return
        }
        playerGrid[r][c] = num
        if num == solution[r][c] {
            score += 10
            consecutiveCorrect += 1
            bestConsecutiveCorrect = max(bestConsecutiveCorrect, consecutiveCorrect)
            let comboBonus = min(consecutiveCorrect, 10) * 2
            score += comboBonus
            streakMultiplier = min(3.0, streakMultiplier + 0.05)
        } else {
            mistakes += 1
            consecutiveCorrect = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.1)
            if mistakes >= maxMistakes {
                gameOver = true; won = false; timer?.invalidate(); phase = .results
                return
            }
        }
        checkCompletion()
    }

    func clearCell() {
        guard let (r, c) = selectedCell, !isOriginal[r][c] else { return }
        playerGrid[r][c] = 0
    }

    func toggleNotes() { notesMode.toggle() }

    func useHint() {
        guard let (r, c) = selectedCell, !isOriginal[r][c], playerGrid[r][c] != solution[r][c] else { return }
        guard hintsUsed < maxHints else { return }
        do { try CurrencyLedger.shared.spendCoins(25) } catch { return }
        playerGrid[r][c] = solution[r][c]; hintsUsed += 1; score += 5
        checkCompletion()
    }

    private func checkCompletion() {
        if playerGrid == solution {
            gameOver = true; won = true; timer?.invalidate()
            let timeBonus = max(0, 600 - Int(elapsedTime))
            let difficultyBonus = difficulty == 2 ? 200 : (difficulty == 1 ? 100 : 50)
            let mistakeBonus = mistakes == 0 ? 100 : 0
            score += difficultyBonus + timeBonus / 10 + mistakeBonus
            streakMultiplier = min(3.0, streakMultiplier + 0.15)
            phase = .results
        }
    }

    func finalReward() -> GameReward {
        let bonus = won ? winXPBonus + (difficulty == 2 ? 50 : 0) : 0
        let xp = Int(Double(baseXPReward + bonus) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier)
        var badge: String?
        if won && difficulty == 2 { badge = "Sudoku Grand Master" }
        if won && mistakes == 0 { badge = badge ?? "Perfect Puzzle" }
        if won && hintsUsed == 0 { badge = badge ?? "No Hints Needed" }
        if won && elapsedTime < 120 && difficulty == 0 { badge = badge ?? "Speed Solver" }
        if won && elapsedTime < 600 && difficulty == 2 { badge = badge ?? "Expert Time" }
        if bestConsecutiveCorrect >= 20 { badge = badge ?? "Sudoku Streak" }
        let gems = won && difficulty >= 1 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }

    deinit { timer?.invalidate() }
}
