import Foundation

final class WordStormLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "word_storm"
    let baseXPReward = 70
    let winXPBonus = 0
    let baseCoinReward = 35
    let winCoinBonus = 0

    @Published var originalWord = ""
    @Published var scrambledLetters: [Character] = []
    @Published var playerInput = ""
    @Published var solvedWords: [String] = []
    @Published var wordsToSolve = 5
    @Published var currentWordIndex = 0
    @Published var hintsAvailable: Int = 0
    @Published var timeRemaining: Double = 60
    @Published var score = 0
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var difficulty = 0
    @Published var consecutiveSolves: Int = 0
    @Published var consecutiveCorrect = 0
    @Published var bestConsecutiveSolves: Int = 0
    @Published var longestWord = 0
    @Published var hintsUsed = 0
    @Published var maxHints = 3
    @Published var bonusTimeEarned: Double = 0
    @Published var perfectRound = true

    private var timer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        score = 0; currentWordIndex = 0; solvedWords = []; gameOver = false
        consecutiveCorrect = 0; consecutiveSolves = 0; bestConsecutiveSolves = 0; longestWord = 0; hintsUsed = 0; bonusTimeEarned = 0; perfectRound = true
        wordsToSolve = 5 + difficulty * 3
        timeRemaining = Double(60 + difficulty * 15)
        let gameLevel = CurrencyLedger.shared.gameStats(for: gameIdentifier).gameLevel
        maxHints = max(1, 3 + (gameLevel >= 5 ? 1 : 0) - difficulty)
        hintsAvailable = maxHints
        phase = .playing; nextWord(); startTimer()
    }

    func nextWord() {
        originalWord = WordStormDictionary.randomWord()
        if difficulty >= 1 && Bool.random() {
            let longWord = WordStormDictionary.randomWord()
            if longWord.count > originalWord.count { originalWord = longWord }
        }
        scrambledLetters = Array(originalWord).shuffled()
        while String(scrambledLetters) == originalWord { scrambledLetters.shuffle() }
        playerInput = ""
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 { self.endGame() }
        }
    }

    func submitAnswer() {
        if playerInput.lowercased() == originalWord.lowercased() {
            solvedWords.append(originalWord)
            consecutiveCorrect += 1
            consecutiveSolves = consecutiveCorrect
            bestConsecutiveSolves = max(bestConsecutiveSolves, consecutiveSolves)
            longestWord = max(longestWord, originalWord.count)

            let lengthBonus = originalWord.count * 10
            let comboBonus = min(consecutiveCorrect, 8) * 15
            let speedBonus = Int(timeRemaining) / 5
            score += lengthBonus + comboBonus + speedBonus

            streakMultiplier = min(3.0, streakMultiplier + 0.1)

            if consecutiveCorrect >= 3 {
                let bonusTime = Double(consecutiveCorrect) * 1.5
                timeRemaining += bonusTime
                bonusTimeEarned += bonusTime
            }

            currentWordIndex += 1
            if currentWordIndex >= wordsToSolve { endGame() }
            else { nextWord() }
        } else {
            streakMultiplier = max(1.0, streakMultiplier - 0.05)
            consecutiveCorrect = 0
            consecutiveSolves = 0
            perfectRound = false
            playerInput = ""
        }
    }

    func tapLetter(_ index: Int) {
        guard index < scrambledLetters.count else { return }
        playerInput.append(scrambledLetters[index])
    }

    func clearInput() { playerInput = "" }

    func useHint() {
        guard hintsUsed < maxHints, !gameOver else { return }
        do { try CurrencyLedger.shared.spendCoins(20) } catch { return }
        hintsUsed += 1
        hintsAvailable = maxHints - hintsUsed
        let revealed = playerInput.count
        if revealed < originalWord.count {
            playerInput = String(originalWord.prefix(revealed + 1))
        }
    }

    func shuffleLetters() {
        scrambledLetters.shuffle()
        while String(scrambledLetters) == originalWord { scrambledLetters.shuffle() }
    }

    private func endGame() {
        timer?.invalidate()
        gameOver = true; phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + solvedWords.count * 10) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 20)
        let diffBonus = difficulty * 15
        var badge: String?
        if solvedWords.count >= wordsToSolve { badge = "Word Storm Champion" }
        if longestWord >= 8 { badge = badge ?? "Wordsmith" }
        if perfectRound && solvedWords.count >= 5 { badge = badge ?? "Perfect Speller" }
        let gems = solvedWords.count >= wordsToSolve && difficulty >= 1 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }

    deinit { timer?.invalidate() }
}
