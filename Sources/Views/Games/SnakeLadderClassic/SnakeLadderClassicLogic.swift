import Foundation

struct SnakeLadderPlayer: Identifiable {
    let id: Int
    let name: String
    var position: Int = 0
    var isHuman: Bool
}

final class SnakeLadderClassicLogic: ObservableObject, GamesRewardable {
    let gameIdentifier = "snake_ladder_classic"
    let baseXPReward = 40
    let winXPBonus = 30
    let baseCoinReward = 20
    let winCoinBonus = 10

    static let snakes: [Int: Int] = [16: 6, 47: 26, 49: 11, 56: 53, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 98: 78]
    static let ladders: [Int: Int] = [1: 38, 4: 14, 9: 31, 21: 42, 28: 84, 36: 44, 51: 67, 71: 91, 80: 100]

    @Published var players: [SnakeLadderPlayer] = []
    @Published var currentPlayerIndex = 0
    @Published var lastDice = 0
    @Published var message = ""
    @Published var gameOver = false
    @Published var winner: SnakeLadderPlayer?
    @Published var phase: GamePhase = .lobby
    @Published var streakMultiplier: Double = 1.0
    @Published var isRolling = false
    @Published var score = 0
    @Published var laddersHit = 0
    @Published var snakesHit = 0
    @Published var turnCount = 0
    @Published var doublesRolled = 0
    @Published var powerUpsAvailable: Int = 0
    @Published var powerUpsUsed: Int = 0
    @Published var totalMoves: Int = 0
    @Published var powerUpAvailable = true
    @Published var difficulty = 0

    enum GamePhase { case lobby, playing, results }

    func startGame(difficulty: Int = 0) {
        self.difficulty = difficulty
        var playerList = [SnakeLadderPlayer(id: 0, name: "You", isHuman: true)]
        let cpuCount = 1 + difficulty
        for i in 0..<cpuCount { playerList.append(SnakeLadderPlayer(id: i + 1, name: "CPU \(i + 1)", isHuman: false)) }
        players = playerList
        currentPlayerIndex = 0; gameOver = false; winner = nil; message = ""; score = 0
        laddersHit = 0; snakesHit = 0; turnCount = 0; doublesRolled = 0; powerUpAvailable = true; powerUpsUsed = 0; totalMoves = 0
        phase = .playing
    }

    func rollDice() {
        guard !gameOver, !isRolling, players[currentPlayerIndex].isHuman else { return }
        performRoll(playerIndex: currentPlayerIndex)
    }

    func usePowerUp() {
        guard powerUpAvailable, players[currentPlayerIndex].isHuman, !gameOver, !isRolling else { return }
        do { try CurrencyLedger.shared.spendCoins(25) } catch { return }
        powerUpAvailable = false
        powerUpsUsed += 1
        let dice1 = Int.random(in: 1...6)
        let dice2 = Int.random(in: 1...6)
        lastDice = max(dice1, dice2)
        processMove(playerIndex: currentPlayerIndex, dice: lastDice)
    }

    private func performRoll(playerIndex: Int) {
        isRolling = true
        turnCount += 1
        if players[playerIndex].isHuman { totalMoves += 1 }
        let dice = Int.random(in: 1...6)
        lastDice = dice
        processMove(playerIndex: playerIndex, dice: dice)
    }

    private func processMove(playerIndex: Int, dice: Int) {
        var newPos = players[playerIndex].position + dice
        if newPos > 100 {
            newPos = players[playerIndex].position
            message = "\(players[playerIndex].name) needs exact roll"
            isRolling = false; advanceTurn(); return
        }

        players[playerIndex].position = newPos
        if newPos == 100 {
            gameOver = true; winner = players[playerIndex]
            if players[playerIndex].isHuman {
                score = 100 + (difficulty * 30) + max(0, 50 - turnCount)
                streakMultiplier = min(3.0, streakMultiplier + 0.2)
            }
            isRolling = false; phase = .results; return
        }

        if let dest = Self.snakes[newPos] {
            message = "\(players[playerIndex].name) hit a snake! \(newPos)\u{2192}\(dest)"
            players[playerIndex].position = dest
            if players[playerIndex].isHuman {
                snakesHit += 1
                streakMultiplier = max(1.0, streakMultiplier - 0.1)
            }
        } else if let dest = Self.ladders[newPos] {
            message = "\(players[playerIndex].name) climbed a ladder! \(newPos)\u{2192}\(dest)"
            players[playerIndex].position = dest
            if players[playerIndex].isHuman {
                score += 15; laddersHit += 1
                streakMultiplier = min(3.0, streakMultiplier + 0.05)
            }
        } else {
            message = "\(players[playerIndex].name) moved to \(newPos)"
        }

        if players[playerIndex].position == 100 {
            gameOver = true; winner = players[playerIndex]
            if players[playerIndex].isHuman { score = 100 + (difficulty * 30) }
            isRolling = false; phase = .results; return
        }
        isRolling = false
        advanceTurn()
    }

    private func advanceTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        if !players[currentPlayerIndex].isHuman {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, !self.gameOver else { return }
                self.performRoll(playerIndex: self.currentPlayerIndex)
            }
        }
    }

    func finalReward() -> GameReward {
        let won = winner?.isHuman == true
        let xp = baseXPReward + (won ? winXPBonus : 0) + (score / 5)
        let coins = baseCoinReward + (won ? winCoinBonus : 0)
        let diffBonus = difficulty * 15
        var badge: String?
        if won && laddersHit >= 5 { badge = "Lucky Climber" }
        if won && snakesHit == 0 { badge = badge ?? "Snake Dodger" }
        if won && turnCount <= 15 { badge = badge ?? "Speed Racer" }
        let gems = won && difficulty >= 2 ? 1 : 0
        return GameReward(xp: max(1, xp + diffBonus), coins: coins, gems: gems, badgeUnlocked: badge)
    }
}
