import Foundation

enum GameStatus: String, Codable {
    case waitingForOpponent
    case inProgress
    case completed
}

struct GameState: Codable {
    let gameID: String
    let status: GameStatus
    let turnCount: Int
    let lastPlayerID: String
    let winningPlayerID: String?

    init(gameID: String, status: GameStatus = .waitingForOpponent, turnCount: Int = 0, lastPlayerID: String = "", winningPlayerID: String? = nil) {
        self.gameID = gameID
        self.status = status
        self.turnCount = turnCount
        self.lastPlayerID = lastPlayerID
        self.winningPlayerID = winningPlayerID
    }
}
