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

    enum GamePhase { case lobby, playing, results }

    func startGame() {
        players = [
            SnakeLadderPlayer(id: 0, name: "You", isHuman: true),
            SnakeLadderPlayer(id: 1, name: "CPU", isHuman: false),
        ]
        currentPlayerIndex = 0; gameOver = false; winner = nil; message = ""; score = 0; phase = .playing
    }

    func rollDice() {
        guard !gameOver, !isRolling, players[currentPlayerIndex].isHuman else { return }
        performRoll(playerIndex: currentPlayerIndex)
    }

    private func performRoll(playerIndex: Int) {
        isRolling = true
        let dice = Int.random(in: 1...6)
        lastDice = dice
        var newPos = players[playerIndex].position + dice
        if newPos > 100 { newPos = players[playerIndex].position; message = "\(players[playerIndex].name) needs exact roll"; isRolling = false; advanceTurn(); return }

        players[playerIndex].position = newPos
        if newPos == 100 { gameOver = true; winner = players[playerIndex]; score = players[playerIndex].isHuman ? 100 : 0; isRolling = false; phase = .results; return }

        if let dest = Self.snakes[newPos] {
            message = "\(players[playerIndex].name) hit a snake! \(newPos)→\(dest)"
            players[playerIndex].position = dest
        } else if let dest = Self.ladders[newPos] {
            message = "\(players[playerIndex].name) climbed a ladder! \(newPos)→\(dest)"
            players[playerIndex].position = dest
            if players[playerIndex].isHuman { score += 10 }
        } else { message = "\(players[playerIndex].name) moved to \(newPos)" }

        if players[playerIndex].position == 100 { gameOver = true; winner = players[playerIndex]; score = players[playerIndex].isHuman ? 100 : 0; isRolling = false; phase = .results; return }
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
        return GameReward(xp: max(1, xp), coins: coins, gems: 0, badgeUnlocked: nil)
    }
}
