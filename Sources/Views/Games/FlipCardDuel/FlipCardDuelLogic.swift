import Foundation

final class FlipCardDuelLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "flip_card_duel"
    let baseXPReward = 25
    let winXPBonus = 30
    let baseCoinReward = 12
    let winCoinBonus = 8

    @Published var playerCard: Int = 0
    @Published var opponentCard: Int = 0
    @Published var playerScore = 0
    @Published var opponentScore = 0
    @Published var round = 0
    @Published var totalRounds = 10
    @Published var result = ""
    @Published var isFlipping = false
    @Published var gameOver = false
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var score = 0

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        playerScore = 0; opponentScore = 0; round = 0; score = 0; gameOver = false
        result = ""; phase = .playing
    }

    func flip() {
        guard !isFlipping, round < totalRounds else { return }
        isFlipping = true; round += 1
        var animCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            animCount += 1
            self.playerCard = Int.random(in: 1...13)
            self.opponentCard = Int.random(in: 1...13)
            if animCount >= 15 {
                timer.invalidate()
                self.playerCard = Int.random(in: 1...13)
                self.opponentCard = Int.random(in: 1...13)
                self.resolveFlip()
            }
        }
    }

    private func resolveFlip() {
        if playerCard > opponentCard {
            result = "You win this round!"; playerScore += 1; score += 20
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else if playerCard < opponentCard {
            result = "Opponent wins!"; opponentScore += 1; streakMultiplier = 1.0
        } else { result = "Tie! War!" }

        isFlipping = false
        if round >= totalRounds { gameOver = true; phase = .results }
    }

    func finalReward() -> GameReward {
        let won = playerScore > opponentScore
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let coins = baseCoinReward + (won ? winCoinBonus : 0)
        return GameReward(xp: max(1, xp), coins: coins, gems: 0, badgeUnlocked: playerScore == totalRounds ? "Card Duel Master" : nil)
    }
}
