import Foundation

final class SequenceRecallLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "sequence_recall"
    let baseXPReward = 50
    let winXPBonus = 0
    let baseCoinReward = 25
    let winCoinBonus = 0

    let colors = ["red", "green", "blue", "yellow", "purple", "orange"]
    @Published var sequence: [Int] = []
    @Published var playerInput: [Int] = []
    @Published var round = 0
    @Published var score = 0
    @Published var lives: Int = 3
    @Published var isShowingSequence = false
    @Published var currentShowIndex = 0
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var bestRound = 0
    @Published var difficulty = 0
    @Published var activeColorCount = 4
    var colorCount: Int { activeColorCount }
    @Published var consecutiveRounds = 0
    @Published var speedMultiplier = 1.0
    @Published var livesRemaining = 1
    @Published var hintsUsed = 0

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        activeColorCount = min(4 + difficulty, colors.count)
        livesRemaining = difficulty == 0 ? 2 : 1
        sequence = []
        playerInput = []
        round = 0
        score = 0
        gameOver = false
        consecutiveRounds = 0
        speedMultiplier = 1.0 - Double(difficulty) * 0.1
        hintsUsed = 0
        phase = .playing
        nextRound()
    }

    func nextRound() {
        round += 1
        sequence.append(Int.random(in: 0..<activeColorCount))
        playerInput = []
        if round > 5 && round % 5 == 0 {
            speedMultiplier = max(0.3, speedMultiplier - 0.05)
        }
        showSequence()
    }

    private func showSequence() {
        isShowingSequence = true
        currentShowIndex = 0
        playNextInSequence()
    }

    private func playNextInSequence() {
        guard currentShowIndex < sequence.count else {
            isShowingSequence = false
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 * speedMultiplier) { [weak self] in
            guard let self = self else { return }
            self.currentShowIndex += 1
            self.playNextInSequence()
        }
    }

    func tapColor(_ index: Int) {
        guard !isShowingSequence, !gameOver else { return }
        playerInput.append(index)
        let pos = playerInput.count - 1
        if playerInput[pos] != sequence[pos] {
            livesRemaining -= 1
            if livesRemaining <= 0 {
                gameOver = true
                bestRound = round - 1
                consecutiveRounds = 0
                streakMultiplier = max(1.0, streakMultiplier - 0.2)
                phase = .results
            } else {
                playerInput = []
                showSequence()
            }
            return
        }
        if playerInput.count == sequence.count {
            consecutiveRounds += 1
            let roundBonus = round * 10
            let speedBonus = Int((1.0 / max(speedMultiplier, 0.3)) * 5)
            let comboBonus = min(consecutiveRounds, 10) * 5
            score += roundBonus + speedBonus + comboBonus
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.nextRound()
            }
        }
    }

    func useHint() {
        guard !gameOver, !isShowingSequence, hintsUsed < 3 else { return }
        do { try CurrencyLedger.shared.spendCoins(20) } catch { return }
        hintsUsed += 1
        showSequence()
    }

    func finalReward() -> GameReward {
        let xp = baseXPReward + (round * 5)
        let totalXP = Int(Double(xp) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 20)
        let difficultyBonus = difficulty * 20
        var badge: String?
        if round >= 15 { badge = "Sequence Master" }
        if round >= 25 { badge = "Sequence Legend" }
        if consecutiveRounds >= 10 { badge = badge ?? "Perfect Recall" }
        let gems = round >= 20 ? 1 : 0
        return GameReward(xp: max(1, totalXP + difficultyBonus), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
