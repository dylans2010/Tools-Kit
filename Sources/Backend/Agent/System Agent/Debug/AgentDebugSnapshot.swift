import Foundation

struct AgentDebugSnapshot: Codable {
    var timestamp: Date
    var state: String
    var messageCount: Int

    init(timestamp: Date = Date(), state: String, messageCount: Int) {
        self.timestamp = timestamp
        self.state = state
        self.messageCount = messageCount
    }
}
