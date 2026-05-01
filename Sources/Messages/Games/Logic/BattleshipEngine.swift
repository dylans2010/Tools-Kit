import Foundation

struct BattleshipEngine: GameProtocol {
    typealias StateType = BattleshipState
    var state: BattleshipState

    init(state: BattleshipState) {
        self.state = state
    }

    func makeMove(action: String) -> BattleshipState {
        // Simple logic for move action strings like "place:1,2,3" or "attack:45"
        var newState = state
        let components = action.split(separator: ":")
        guard components.count == 2 else { return state }

        let type = components[0]
        let value = components[1]

        if type == "place" {
            let indices = value.split(separator: ",").compactMap { Int($0) }
            if !state.player1ShipsPlaced {
                var board = state.player1Board
                indices.forEach { board[$0] = 1 }
                newState = BattleshipState(base: state.base, player1Board: board, player2Board: state.player2Board, player1ShipsPlaced: true, player2ShipsPlaced: state.player2ShipsPlaced, isPlayer1Turn: state.isPlayer1Turn)
            } else if !state.player2ShipsPlaced {
                var board = state.player2Board
                indices.forEach { board[$0] = 1 }
                newState = BattleshipState(base: state.base, player1Board: state.player1Board, player2Board: board, player1ShipsPlaced: state.player1ShipsPlaced, player2ShipsPlaced: true, isPlayer1Turn: state.isPlayer1Turn)
            }
        } else if type == "attack" {
            guard let index = Int(value) else { return state }
            if state.isPlayer1Turn {
                var board = state.player2Board
                board[index] = board[index] == 1 ? 2 : 3
                newState = BattleshipState(base: state.base, player1Board: state.player1Board, player2Board: board, player1ShipsPlaced: state.player1ShipsPlaced, player2ShipsPlaced: state.player2ShipsPlaced, isPlayer1Turn: false)
            } else {
                var board = state.player1Board
                board[index] = board[index] == 1 ? 2 : 3
                newState = BattleshipState(base: state.base, player1Board: board, player2Board: state.player2Board, player1ShipsPlaced: state.player1ShipsPlaced, player2ShipsPlaced: state.player2ShipsPlaced, isPlayer1Turn: true)
            }
        }

        return newState
    }

    func encodeState() -> Data? {
        JSONCoder.encode(state)
    }

    static func decodeState(from data: Data) -> BattleshipState? {
        JSONCoder.decode(BattleshipState.self, from: data)
    }
}
