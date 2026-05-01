import Foundation

struct TapRaceState: Codable {
    let base: GameState
    let player1Taps: Int
    let player2Taps: Int
    let isPlayer1Turn: Bool
    let isFinished: Bool

    init(gameID: String) {
        self.base = GameState(gameID: gameID)
        self.player1Taps = 0
        self.player2Taps = 0
        self.isPlayer1Turn = true
        self.isFinished = false
    }
}
