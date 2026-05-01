import Foundation

struct BasketballState: Codable {
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
}
