import Foundation
import Messages

@MainActor
class GameEngine {
    nonisolated(unsafe) static let shared = GameEngine()

    private init() {}

    func processMove<T: GameProtocol>(game: T, action: String, session: MSSession?, summary: String) -> MSMessage {
        var mutableGame = game
        let newState = mutableGame.makeMove(action: action)

        guard let data = JSONCoder.encode(newState) else {
            fatalError("Failed to encode game state")
        }

        let subtype: PayloadSubtype
        if T.self == BattleshipEngine.self {
            subtype = .battleship
        } else if T.self == BasketballEngine.self {
            subtype = .basketball
        } else {
            subtype = .tapRace
        }

        let payload = MessagePayload(type: .game, subtype: subtype, data: data)
        return MessageManager.shared.createMessage(payload: payload, session: session, summary: summary)
    }
}
