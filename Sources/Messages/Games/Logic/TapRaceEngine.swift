import Foundation

struct TapRaceEngine: GameProtocol, Sendable {
    typealias StateType = TapRaceState
    var state: TapRaceState

    init(state: TapRaceState) {
        self.state = state
    }

    func makeMove(action: String) -> TapRaceState {
        // action: "finish:TAPS_COUNT"
        var newState = state
        let components = action.split(separator: ":")
        guard components.count == 2, components[0] == "finish" else { return state }

        guard let taps = Int(components[1]) else { return state }

        if state.isPlayer1Turn {
            newState = TapRaceState(base: state.base, player1Taps: taps, player2Taps: state.player2Taps, isPlayer1Turn: false, isFinished: false)
        } else {
            newState = TapRaceState(base: state.base, player1Taps: state.player1Taps, player2Taps: taps, isPlayer1Turn: true, isFinished: true)
        }

        return newState
    }

    func encodeState() -> Data? {
        JSONCoder.encode(state)
    }

    static func decodeState(from data: Data) -> TapRaceState? {
        JSONCoder.decode(TapRaceState.self, from: data)
    }
}
