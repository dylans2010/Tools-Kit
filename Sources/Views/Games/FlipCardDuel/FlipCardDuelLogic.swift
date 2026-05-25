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
    @Published var difficulty = 0
    @Published var consecutiveWins = 0
    @Published var bestConsecutiveWins = 0
    @Published var warCount = 0
    @Published var warWins = 0
    @Published var doubleOrNothingActive = false
    @Published var doubleOrNothingMultiplier = 1

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        playerScore = 0; opponentScore = 0; round = 0; score = 0; gameOver = false
        result = ""; consecutiveWins = 0; bestConsecutiveWins = 0
        warCount = 0; warWins = 0; doubleOrNothingActive = false; doubleOrNothingMultiplier = 1
        totalRounds = 10 + difficulty * 5
        phase = .playing
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
                let opponentBias = self.difficulty >= 2 ? Int.random(in: 0...2) : 0
                self.opponentCard = min(13, Int.random(in: 1...13) + opponentBias)
                self.resolveFlip()
            }
        }
    }

    func activateDoubleOrNothing() {
        guard !doubleOrNothingActive, consecutiveWins >= 2 else { return }
        doubleOrNothingActive = true
        doubleOrNothingMultiplier = 2
    }

    private func resolveFlip() {
        let pointValue = 20 * doubleOrNothingMultiplier
        if playerCard > opponentCard {
            result = "You win this round!"; playerScore += 1; score += pointValue
            consecutiveWins += 1
            bestConsecutiveWins = max(bestConsecutiveWins, consecutiveWins)
            streakMultiplier = min(3.0, streakMultiplier + 0.1)
        } else if playerCard < opponentCard {
            result = "Opponent wins!"; opponentScore += 1
            consecutiveWins = 0
            streakMultiplier = max(1.0, streakMultiplier - 0.05)
            if doubleOrNothingActive {
                score = max(0, score - pointValue)
                doubleOrNothingActive = false; doubleOrNothingMultiplier = 1
            }
        } else {
            result = "Tie! War!"; warCount += 1
            resolveWar()
        }

        isFlipping = false
        if round >= totalRounds { gameOver = true; phase = .results }
    }

    private func resolveWar() {
        let warPlayer = Int.random(in: 1...13)
        let warOpponent = Int.random(in: 1...13)
        if warPlayer >= warOpponent {
            warWins += 1
            score += 40 * doubleOrNothingMultiplier
            playerScore += 1
            result = "War won! \(warPlayer) vs \(warOpponent)"
        } else {
            opponentScore += 1
            result = "War lost! \(warPlayer) vs \(warOpponent)"
        }
    }

    func finalReward() -> GameReward {
        let won = playerScore > opponentScore
        let xp = Int(Double(baseXPReward + (won ? winXPBonus : 0)) * streakMultiplier) + (score / 10)
        let coins = baseCoinReward + (won ? winCoinBonus : 0)
        let diffBonus = difficulty * 15
        var badge: String?
        if playerScore == totalRounds { badge = "Card Duel Master" }
        if bestConsecutiveWins >= 7 { badge = badge ?? "Winning Streak" }
        if warWins >= 3 { badge = badge ?? "War Hero" }
        if won && difficulty >= 2 { badge = badge ?? "Duel Champion" }
        let gems = playerScore == totalRounds ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: coins, gems: gems, badgeUnlocked: badge)
    }
}
