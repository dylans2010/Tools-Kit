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
    @Published var score = 0
    @Published var round = 0
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var selectedCell: (row: Int, col: Int)?

    enum GamePhase { case lobby, playing, results }

    private let sizes = [3, 4, 5]

    func startGame(difficulty: Int) {
        gridSize = sizes[min(difficulty, sizes.count - 1)]
        score = 0
        round = 1
        gameOver = false
        phase = .playing
        generateGrid()
    }

    private func generateGrid() {
        grid = (0..<gridSize).map { _ in (0..<gridSize).map { _ in Int.random(in: 1...9) } }
        playerGrid = Array(repeating: Array(repeating: nil as Int?, count: gridSize), count: gridSize)
        isMemorizing = true
        let delay = Double(gridSize) * 1.2
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
        let total = gridSize * gridSize
        score += correct * 15
        if correct == total {
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            score += 50
        } else {
            streakMultiplier = 1.0
        }
        gameOver = true
        phase = .results
    }

    func finalReward() -> GameReward {
        calculateFinalReward(won: true, score: score, streakMultiplier: streakMultiplier)
    }
}
