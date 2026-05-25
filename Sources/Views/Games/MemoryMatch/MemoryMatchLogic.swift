import Foundation

struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    var isFaceUp = false
    var isMatched = false
}

final class MemoryMatchLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "memory_match"
    let baseXPReward = 60
    let winXPBonus = 0
    let baseCoinReward = 30
    let winCoinBonus = 0

    @Published var cards: [MemoryCard] = []
    @Published var firstFlipped: Int?
    @Published var moves = 0
    @Published var matchesFound = 0
    @Published var totalPairs = 0
    @Published var difficulty = 0
    @Published var isTimerMode = false
    @Published var timeRemaining: Double = 60
    @Published var score = 0
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var isProcessing = false

    enum GamePhase { case lobby, playing, results }

    private let grids: [(rows: Int, cols: Int)] = [(4, 4), (5, 4), (6, 5)]

    func startGame(difficulty: Int, timerMode: Bool) {
        self.difficulty = difficulty
        self.isTimerMode = timerMode
        let (rows, cols) = grids[min(difficulty, grids.count - 1)]
        totalPairs = (rows * cols) / 2
        let symbols = ["star.fill", "heart.fill", "bolt.fill", "moon.fill", "sun.max.fill", "cloud.fill",
                       "flame.fill", "leaf.fill", "drop.fill", "snowflake", "wind", "tornado",
                       "sparkles", "globe", "eye.fill"]
        let selected = Array(symbols.prefix(totalPairs))
        var deck = (selected + selected).shuffled()
        cards = deck.map { MemoryCard(symbol: $0) }
        moves = 0
        matchesFound = 0
        score = 0
        gameOver = false
        firstFlipped = nil
        timeRemaining = timerMode ? Double(totalPairs * 8) : 999
        phase = .playing
    }

    func flipCard(at index: Int) {
        guard !isProcessing, !cards[index].isFaceUp, !cards[index].isMatched, !gameOver else { return }
        cards[index].isFaceUp = true

        if let first = firstFlipped {
            moves += 1
            isProcessing = true
            if cards[first].symbol == cards[index].symbol {
                cards[first].isMatched = true
                cards[index].isMatched = true
                matchesFound += 1
                score += max(10, 50 - moves)
                streakMultiplier = min(3.0, streakMultiplier + 0.1)
                firstFlipped = nil
                isProcessing = false
                if matchesFound == totalPairs { endGame() }
            } else {
                streakMultiplier = 1.0
                let f = first
                let s = index
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                    self?.cards[f].isFaceUp = false
                    self?.cards[s].isFaceUp = false
                    self?.firstFlipped = nil
                    self?.isProcessing = false
                }
            }
        } else {
            firstFlipped = index
        }
    }

    private func endGame() {
        gameOver = true
        score += max(0, 200 - moves * 3)
        phase = .results
    }

    func finalReward() -> GameReward {
        calculateFinalReward(won: matchesFound == totalPairs, score: score, streakMultiplier: streakMultiplier)
    }
}
