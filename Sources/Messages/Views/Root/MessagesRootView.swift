import SwiftUI
import Messages

struct MessagesRootView: View {
    @State private var selectedTab = 0
    @State private var activePayload: MessagePayload?
    @State private var activeAIPath: PayloadSubtype?

    var onSendMessage: (MSMessage) -> Void
    var onActivePayloadChanged: (MessagePayload?) -> Void

    init(activePayload: MessagePayload?, onSendMessage: @escaping (MSMessage) -> Void, onActivePayloadChanged: @escaping (MessagePayload?) -> Void) {
        self._activePayload = State(initialValue: activePayload)
        self.onSendMessage = onSendMessage
        self.onActivePayloadChanged = onActivePayloadChanged
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if activePayload == nil && activeAIPath == nil {
                    SegmentSwitcher(selection: $selectedTab, options: ["🎮 Games", "🤖 AI Tools"])

                    if selectedTab == 0 {
                        GamesHomeView { subtype in
                            startNewGame(subtype)
                        }
                    } else {
                        MessagesAIHomeView { subtype in
                            activeAIPath = subtype
                        }
                    }
                } else if let payload = activePayload, payload.type == .game {
                    gameView(for: payload)
                } else if let aiPath = activeAIPath {
                    aiToolView(for: aiPath)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if activePayload != nil || activeAIPath != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            activePayload = nil
                            activeAIPath = nil
                            onActivePayloadChanged(nil)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func gameView(for payload: MessagePayload) -> some View {
        switch payload.subtype {
        case .battleship:
            if let state = JSONCoder.decode(BattleshipState.self, from: payload.data) {
                BattleshipView(state: state) { action in
                    let engine = BattleshipEngine(state: state)
                    let newState = engine.makeMove(action: action)
                    sendGameMove(newState, subtype: .battleship, summary: "Battleship Move")
                }
            }
        case .basketball:
            if let state = JSONCoder.decode(BasketballState.self, from: payload.data) {
                BasketballView(state: state) { action in
                    let engine = BasketballEngine(state: state)
                    let newState = engine.makeMove(action: action)
                    sendGameMove(newState, subtype: .basketball, summary: "Basketball Shoot")
                }
            }
        case .tapRace:
            if let state = JSONCoder.decode(TapRaceState.self, from: payload.data) {
                TapRaceView(state: state) { action in
                    let engine = TapRaceEngine(state: state)
                    let newState = engine.makeMove(action: action)
                    sendGameMove(newState, subtype: .tapRace, summary: "Tap Race Finish")
                }
            }
        default:
            Text("Unknown Game")
        }
    }

    @ViewBuilder
    private func aiToolView(for subtype: PayloadSubtype) -> some View {
        switch subtype {
        case .rewrite:
            MessagesRewriteTool { result in sendAIResult(result) }
        case .summarize:
            MessagesSummarizeTool { result in sendAIResult(result) }
        case .reply:
            MessagesReplyGenerator { result in sendAIResult(result) }
        default:
            Text("Unknown AI Tool")
        }
    }

    private func startNewGame(_ subtype: PayloadSubtype) {
        let gameID = UUID().uuidString
        let data: Data?
        let summary: String

        switch subtype {
        case .battleship:
            data = JSONCoder.encode(BattleshipState(gameID: gameID))
            summary = "Let's play Battleship!"
        case .basketball:
            data = JSONCoder.encode(BasketballState(gameID: gameID))
            summary = "Let's play Basketball!"
        case .tapRace:
            data = JSONCoder.encode(TapRaceState(gameID: gameID))
            summary = "Let's play Tap Race!"
        default: return
        }

        if let data = data {
            let payload = MessagePayload(type: .game, subtype: subtype, data: data)
            activePayload = payload
            onActivePayloadChanged(payload)
            let message = MessageManager.shared.createMessage(payload: payload, session: nil, summary: summary)
            onSendMessage(message)
        }
    }

    private func sendGameMove<T: Codable>(_ state: T, subtype: PayloadSubtype, summary: String) {
        if let data = JSONCoder.encode(state) {
            let payload = MessagePayload(type: .game, subtype: subtype, data: data)
            activePayload = payload
            onActivePayloadChanged(payload)
            let message = MessageManager.shared.createMessage(payload: payload, session: nil, summary: summary)
            onSendMessage(message)
        }
    }

    private func sendAIResult(_ result: AIResult) {
        if let data = JSONCoder.encode(result) {
            let payload = MessagePayload(type: .ai, subtype: result.subtype, data: data)
            let message = MessageManager.shared.createMessage(payload: payload, session: nil, summary: "AI: \(result.subtype.rawValue)")
            onSendMessage(message)
            activeAIPath = nil
        }
    }
}
