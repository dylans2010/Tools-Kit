import Foundation

final class SoundMatchLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "sound_match"
    let baseXPReward = 20; let winXPBonus = 15; let baseCoinReward = 12; let winCoinBonus = 8

    enum GamePhase { case lobby, playing, results }
    @Published var phase: GamePhase = .lobby
    @Published var score = 0; @Published var difficulty = 0; @Published var streakMultiplier: Double = 1.0
    @Published var round = 0; @Published var totalRounds = 10; @Published var won = false
    @Published var sequence: [Int] = []; @Published var playerInput: [Int] = []
    @Published var showingSequence = true; @Published var sequenceLength = 3
    @Published var correctCount = 0; @Published var mistakes = 0; @Published var maxMistakes = 3
    @Published var consecutiveCorrect = 0; @Published var bestStreak = 0
    @Published var gridItems = 0

    private let easySizes = [Int]([3])
    private let medSizes = [Int]([4])
    private let hardSizes = [Int]([5])

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        sequenceLength = difficulty == 0 ? 3 : (difficulty == 1 ? 4 : 5)
        totalRounds = 8 + difficulty * 3; maxMistakes = 3 - difficulty / 2
        round = 0; score = 0; correctCount = 0; mistakes = 0; won = false
        consecutiveCorrect = 0; bestStreak = 0; streakMultiplier = 1.0
        gridItems = sequenceLength + 2 + difficulty
        phase = .playing; nextRound()
    }

    func nextRound() {
        round += 1; playerInput = []; showingSequence = true
        sequence = (0..<sequenceLength).map { _ in Int.random(in: 0..<gridItems) }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(sequenceLength) * 0.6 + 1.0) { [weak self] in
            self?.showingSequence = false
        }
    }

    func selectItem(_ index: Int) {
        guard !showingSequence else { return }
        playerInput.append(index)
        let pos = playerInput.count - 1
        if pos < sequence.count && sequence[pos] == index {
            consecutiveCorrect += 1; bestStreak = max(bestStreak, consecutiveCorrect)
            score += Int(Double(20 + difficulty * 10) * streakMultiplier)
            streakMultiplier = min(3.0, streakMultiplier + 0.08)
            if playerInput.count == sequence.count {
                correctCount += 1
                if round >= totalRounds { won = true; phase = .results }
                else {
                    if round % 3 == 0 { sequenceLength += 1; gridItems += 1 }
                    nextRound()
                }
            }
        } else {
            mistakes += 1; consecutiveCorrect = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.15)
            if mistakes >= maxMistakes { won = false; phase = .results }
            else { nextRound() }
        }
    }

    func finalReward() -> GameReward {
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + score / 10
        let coins = Int(Double(baseCoinReward + (won ? winCoinBonus : 0)) * streakMultiplier) + score / 20
        var badge: String? = nil
        if correctCount >= totalRounds { badge = "Perfect Memory" }
        if bestStreak >= 8 { badge = badge ?? "Memory Streak" }
        if mistakes == 0 && won { badge = badge ?? "Flawless Mind" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp), coins: max(0, coins), gems: gems, badgeUnlocked: badge)
    }
}
