import Foundation

final class SequenceRecallLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "sequence_recall"
    let baseXPReward = 50
    let winXPBonus = 0
    let baseCoinReward = 25
    let winCoinBonus = 0

    let colors = ["red", "green", "blue", "yellow"]
    @Published var sequence: [Int] = []
    @Published var playerInput: [Int] = []
    @Published var round = 0
    @Published var score = 0
    @Published var isShowingSequence = false
    @Published var currentShowIndex = 0
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var bestRound = 0

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        sequence = []
        playerInput = []
        round = 0
        score = 0
        gameOver = false
        phase = .playing
        nextRound()
    }

    func nextRound() {
        round += 1
        sequence.append(Int.random(in: 0..<colors.count))
        playerInput = []
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
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
            gameOver = true
            bestRound = round - 1
            phase = .results
            return
        }
        if playerInput.count == sequence.count {
            score += round * 10
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.nextRound()
            }
        }
    }

    func finalReward() -> GameReward {
        let xp = baseXPReward + (round * 5)
        let totalXP = Int(Double(xp) * streakMultiplier) + (score / 10)
        let coins = Int(Double(baseCoinReward) * streakMultiplier) + (score / 20)
        return GameReward(xp: max(1, totalXP), coins: max(0, coins), gems: 0, badgeUnlocked: round >= 15 ? "Sequence Master" : nil)
    }
}
