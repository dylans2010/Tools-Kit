import Foundation

struct BasketballEngine: GameProtocol, Sendable {
    typealias StateType = BasketballState
    var state: BasketballState

    init(state: BasketballState) {
        self.state = state
    }

    func makeMove(action: String) -> BasketballState {
        // action: "shoot:success|fail"
        var newState = state
        let components = action.split(separator: ":")
        guard components.count == 2, components[0] == "shoot" else { return state }

        let success = components[1] == "success"
        let points = success ? 2 : 0

        if state.isPlayer1Turn {
            newState = BasketballState(base: state.base, player1Score: state.player1Score + points, player2Score: state.player2Score, isPlayer1Turn: false, roundsPlayed: state.roundsPlayed)
        } else {
            newState = BasketballState(base: state.base, player1Score: state.player1Score, player2Score: state.player2Score + points, isPlayer1Turn: true, roundsPlayed: state.roundsPlayed + 1)
        }

        return newState
    }

    func encodeState() -> Data? {
        JSONCoder.encode(state)
    }

    static func decodeState(from data: Data) -> BasketballState? {
        JSONCoder.decode(BasketballState.self, from: data)
    }
}
