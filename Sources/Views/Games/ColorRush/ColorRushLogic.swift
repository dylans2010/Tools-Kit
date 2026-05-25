import Foundation

final class ColorRushLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "color_rush"
    let baseXPReward = 25
    let winXPBonus = 0
    let baseCoinReward = 12
    let winCoinBonus = 0

    let colorNames = ["Red", "Blue", "Green", "Yellow", "Purple", "Orange"]
    let colorIndices = [0, 1, 2, 3, 4, 5]

    @Published var displayedWord = ""
    @Published var displayedColorIndex = 0
    @Published var correctColorIndex = 0
    @Published var score = 0
    @Published var timeRemaining: Double = 30
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0

    private var timer: Timer?

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        score = 0; timeRemaining = 30; gameOver = false; phase = .playing
        generateRound(); startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 { self.endGame() }
        }
    }

    func generateRound() {
        let wordIdx = Int.random(in: 0..<colorNames.count)
        displayedWord = colorNames[wordIdx]
        displayedColorIndex = Int.random(in: 0..<colorNames.count)
        correctColorIndex = displayedColorIndex
    }

    func selectColor(_ index: Int) {
        if index == correctColorIndex {
            score += 10; streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else { streakMultiplier = 1.0 }
        generateRound()
    }

    private func endGame() { timer?.invalidate(); gameOver = true; phase = .results }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward) * streakMultiplier) + (score / 5)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 10)
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: 0, badgeUnlocked: score >= 200 ? "Color Expert" : nil)
    }

    deinit { timer?.invalidate() }
}
