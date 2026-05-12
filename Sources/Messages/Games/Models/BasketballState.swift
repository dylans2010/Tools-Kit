import Foundation

struct BasketballState: Codable, Sendable {
    let base: GameState
    let player1Score: Int
    let player2Score: Int
    let isPlayer1Turn: Bool
    let roundsPlayed: Int

    init(gameID: String) {
        self.base = GameState(gameID: gameID)
        self.player1Score = 0
        self.player2Score = 0
        self.isPlayer1Turn = true
        self.roundsPlayed = 0
    }

    init(base: GameState, player1Score: Int, player2Score: Int, isPlayer1Turn: Bool, roundsPlayed: Int) {
        self.base = base
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.isPlayer1Turn = isPlayer1Turn
        self.roundsPlayed = roundsPlayed
    }
}
