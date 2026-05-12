import Foundation

struct TapRaceState: Codable, Sendable {
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

    init(base: GameState, player1Taps: Int, player2Taps: Int, isPlayer1Turn: Bool, isFinished: Bool) {
        self.base = base
        self.player1Taps = player1Taps
        self.player2Taps = player2Taps
        self.isPlayer1Turn = isPlayer1Turn
        self.isFinished = isFinished
    }
}
