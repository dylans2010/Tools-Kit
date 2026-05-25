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
    @Published var timeRemaining: Double = 60
    @Published var score = 0
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0

    private var timer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        score = 0; currentWordIndex = 0; solvedWords = []; gameOver = false; timeRemaining = 60
        phase = .playing; nextWord(); startTimer()
    }

    func nextWord() {
        originalWord = WordStormDictionary.randomWord()
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
            score += originalWord.count * 10
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            currentWordIndex += 1
            if currentWordIndex >= wordsToSolve { endGame() }
            else { nextWord() }
        } else {
            streakMultiplier = 1.0
            playerInput = ""
        }
    }

    func tapLetter(_ index: Int) {
        guard index < scrambledLetters.count else { return }
        playerInput.append(scrambledLetters[index])
    }

    func clearInput() { playerInput = "" }

    private func endGame() {
        timer?.invalidate()
        gameOver = true; phase = .results
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + solvedWords.count * 10) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 20)
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: 0, badgeUnlocked: solvedWords.count >= 5 ? "Word Master" : nil)
    }

    deinit { timer?.invalidate() }
}
