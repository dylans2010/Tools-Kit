import Foundation

final class NumberVaultLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "number_vault"
    let baseXPReward = 55
    let winXPBonus = 0
    let baseCoinReward = 28
    let winCoinBonus = 0

    @Published var grid: [[Int]] = []
    @Published var playerGrid: [[Int?]] = []
    @Published var gridSize = 3
    @Published var isMemorizing = true
    @Published var perfectStreak: Int = 0
    @Published var correctCount: Int = 0
    @Published var score = 0
    @Published var round = 0
    @Published var totalRounds = 3
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var selectedCell: (row: Int, col: Int)?
    @Published var difficulty = 0
    @Published var correctCells = 0
    @Published var totalCells = 0
    @Published var consecutivePerfect = 0
    @Published var memorizeTime: Double = 0
    @Published var hintsUsed = 0
    @Published var maxHints = 2

    enum GamePhase { case lobby, playing, results }

    private let sizes = [3, 4, 5]

    func startGame(difficulty: Int) {
        self.difficulty = difficulty
        gridSize = sizes[min(difficulty, sizes.count - 1)]
        score = 0
        round = 0
        totalRounds = 3 + difficulty
        gameOver = false
        consecutivePerfect = 0
        hintsUsed = 0
        let gameLevel = CurrencyLedger.shared.gameStats(for: gameIdentifier).gameLevel
        maxHints = max(1, 2 + (gameLevel >= 5 ? 1 : 0) - difficulty)
        phase = .playing
        nextRound()
    }

    private func nextRound() {
        round += 1
        correctCells = 0
        totalCells = gridSize * gridSize
        generateGrid()
    }

    private func generateGrid() {
        let maxNum = difficulty >= 2 ? 20 : 9
        grid = (0..<gridSize).map { _ in (0..<gridSize).map { _ in Int.random(in: 1...maxNum) } }
        playerGrid = Array(repeating: Array(repeating: nil as Int?, count: gridSize), count: gridSize)
        isMemorizing = true
        memorizeTime = Double(gridSize) * (1.2 - Double(difficulty) * 0.15)
        let delay = memorizeTime
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.isMemorizing = false
        }
    }

    func inputNumber(_ number: Int, row: Int, col: Int) {
        guard !isMemorizing, !gameOver else { return }
        playerGrid[row][col] = number
    }

    func submitGrid() {
        var correct = 0
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if playerGrid[r][c] == grid[r][c] { correct += 1 }
            }
        }
        correctCells = correct
        let total = gridSize * gridSize
        let accuracy = Double(correct) / Double(total)
        score += correct * 15

        if correct == total {
            streakMultiplier = min(3.0, streakMultiplier + 0.15)
            score += 50 + (round * 25)
            consecutivePerfect += 1
            if consecutivePerfect >= 2 { score += 100 * consecutivePerfect }
        } else {
            streakMultiplier = max(1.0, streakMultiplier - 0.1)
            consecutivePerfect = 0
        }

        if accuracy >= 0.8 { score += 30 }

        if round < totalRounds {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.nextRound()
            }
        } else {
            gameOver = true
            phase = .results
        }
    }

    func useHint() {
        guard !isMemorizing, hintsUsed < maxHints, !gameOver else { return }
        do { try CurrencyLedger.shared.spendCoins(15) } catch { return }
        hintsUsed += 1
        if let (r, c) = selectedCell, playerGrid[r][c] != grid[r][c] {
            playerGrid[r][c] = grid[r][c]
        } else {
            for r in 0..<gridSize {
                for c in 0..<gridSize {
                    if playerGrid[r][c] == nil {
                        playerGrid[r][c] = grid[r][c]
                        return
                    }
                }
            }
        }
    }

    func finalReward() -> GameReward {
        var reward = calculateFinalReward(won: true, score: score, streakMultiplier: streakMultiplier)
        let diffBonus = difficulty * 20
        var badge = reward.badgeUnlocked
        if consecutivePerfect >= totalRounds { badge = badge ?? "Photographic Memory" }
        if score >= 500 { badge = badge ?? "Number Savant" }
        let gems = consecutivePerfect >= totalRounds ? 1 : reward.gems
        reward = GameReward(xp: reward.xp + diffBonus, coins: reward.coins, gems: gems, badgeUnlocked: badge)
        return reward
    }
}
