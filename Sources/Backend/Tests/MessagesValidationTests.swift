import Foundation

struct MessagesValidationTests: Sendable {
    static func run() {
        print("Testing Messages Extension Logic...")

        // 1. JSONCoder
        let testPayload = ["key": "value"]
        if let data = JSONCoder.encode(testPayload),
           let decoded = JSONCoder.decode([String: String].self, from: data),
           decoded["key"] == "value" {
            print("✅ JSONCoder verified")
        } else {
            fatalError("❌ JSONCoder failed")
        }

        // 2. MessagePayload
        let data = "test".data(using: .utf8)!
        let payload = MessagePayload(type: .game, subtype: .battleship, data: data)
        assert(payload.type == .game)
        assert(payload.subtype == .battleship)
        print("✅ MessagePayload verified")

        // 3. BattleshipEngine
        let battleshipState = BattleshipState(gameID: "test")
        var battleshipEngine = BattleshipEngine(state: battleshipState)
        let placedState = battleshipEngine.makeMove(action: "place:0,1,2")
        assert(placedState.player1ShipsPlaced)
        assert(placedState.player1Board[0] == 1)
        print("✅ BattleshipEngine verified")

        // 4. BasketballEngine
        let basketballState = BasketballState(gameID: "test")
        var basketballEngine = BasketballEngine(state: basketballState)
        let shotState = basketballEngine.makeMove(action: "shoot:success")
        assert(shotState.player1Score == 2)
        assert(!shotState.isPlayer1Turn)
        print("✅ BasketballEngine verified")

        // 5. TapRaceEngine
        let tapRaceState = TapRaceState(gameID: "test")
        var tapRaceEngine = TapRaceEngine(state: tapRaceState)
        let finishedState = tapRaceEngine.makeMove(action: "finish:100")
        assert(finishedState.player1Taps == 100)
        assert(!finishedState.isPlayer1Turn)
        print("✅ TapRaceEngine verified")

        print("Messages Extension Logic Verified.")
    }

    private static func assert(_ condition: Bool, message: String = "Assertion failed") {
        if !condition {
            fatalError(message)
        }
    }
}
