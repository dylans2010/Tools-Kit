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
    @Published var consecutiveMatches = 0
    @Published var perfectGame = true
    @Published var hintsUsed = 0
    @Published var maxHints = 3

    private var timer: Timer?

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
        let deck = (selected + selected).shuffled()
        cards = deck.map { MemoryCard(symbol: $0) }
        moves = 0
        matchesFound = 0
        score = 0
        gameOver = false
        firstFlipped = nil
        consecutiveMatches = 0
        perfectGame = true
        hintsUsed = 0
        let gameLevel = CurrencyLedger.shared.gameStats(for: gameIdentifier).gameLevel
        maxHints = max(1, 3 - difficulty + (gameLevel >= 5 ? 1 : 0))
        timeRemaining = timerMode ? Double(totalPairs * 8) : 999
        phase = .playing
        if timerMode { startTimer() }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isTimerMode else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 { self.timeRemaining = 0; self.endGame() }
        }
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
                consecutiveMatches += 1

                let comboBonus = min(consecutiveMatches, 5)
                let baseScore = max(10, 50 - moves)
                score += baseScore * comboBonus
                if consecutiveMatches >= 3 { score += 25 * consecutiveMatches }

                streakMultiplier = min(3.0, streakMultiplier + 0.05 * Double(comboBonus))
                firstFlipped = nil
                isProcessing = false
                if isTimerMode && consecutiveMatches >= 2 { timeRemaining += Double(consecutiveMatches) }
                if matchesFound == totalPairs { endGame() }
            } else {
                streakMultiplier = max(1.0, streakMultiplier - 0.1)
                consecutiveMatches = 0
                perfectGame = false
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

    func useHint() {
        guard hintsUsed < maxHints, !gameOver else { return }
        let unmatched = cards.enumerated().filter { !$0.element.isMatched && !$0.element.isFaceUp }
        guard unmatched.count >= 2 else { return }
        do { try CurrencyLedger.shared.spendCoins(15) } catch { return }
        hintsUsed += 1
        let first = unmatched[0]
        if let match = unmatched.dropFirst().first(where: { $0.element.symbol == first.element.symbol }) {
            cards[first.offset].isFaceUp = true
            cards[match.offset].isFaceUp = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.cards[first.offset].isFaceUp = false
                self.cards[match.offset].isFaceUp = false
            }
        }
    }

    private func endGame() {
        timer?.invalidate()
        gameOver = true
        let won = matchesFound == totalPairs
        if won {
            score += max(0, 200 - moves * 3)
            score += difficulty * 50
            if perfectGame { score += 300 }
            if isTimerMode { score += Int(timeRemaining) * 2 }
        }
        phase = .results
    }

    func finalReward() -> GameReward {
        let won = matchesFound == totalPairs
        var reward = calculateFinalReward(won: won, score: score, streakMultiplier: streakMultiplier)
        let difficultyBonus = difficulty * 15
        var gems = reward.gems
        if perfectGame && won { gems += 1 }
        var badge = reward.badgeUnlocked
        if perfectGame && won && difficulty >= 2 { badge = badge ?? "Perfect Memory" }
        if moves <= totalPairs && won { badge = badge ?? "Memory Genius" }
        reward = GameReward(xp: reward.xp + difficultyBonus, coins: reward.coins + (perfectGame ? 20 : 0), gems: gems, badgeUnlocked: badge)
        return reward
    }

    deinit { timer?.invalidate() }
}
