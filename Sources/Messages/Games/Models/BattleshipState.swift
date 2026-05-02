import Foundation

struct BattleshipState: Codable {
    let base: GameState
    let player1Board: [Int] // 0: empty, 1: ship, 2: hit, 3: miss
    let player2Board: [Int]
    let player1ShipsPlaced: Bool
    let player2ShipsPlaced: Bool
    let isPlayer1Turn: Bool

    init(gameID: String) {
        self.base = GameState(gameID: gameID)
        self.player1Board = Array(repeating: 0, count: 100)
        self.player2Board = Array(repeating: 0, count: 100)
        self.player1ShipsPlaced = false
        self.player2ShipsPlaced = false
        self.isPlayer1Turn = true
    }

    init(base: GameState, player1Board: [Int], player2Board: [Int], player1ShipsPlaced: Bool, player2ShipsPlaced: Bool, isPlayer1Turn: Bool) {
        self.base = base
        self.player1Board = player1Board
        self.player2Board = player2Board
        self.player1ShipsPlaced = player1ShipsPlaced
        self.player2ShipsPlaced = player2ShipsPlaced
        self.isPlayer1Turn = isPlayer1Turn
    }
}
