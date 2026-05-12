import Foundation

struct AgentToolResult: Codable, Sendable {
    let toolCallId: String
    let result: String
    let isError: Bool

    init(toolCallId: String, result: String, isError: Bool = false) {
        self.toolCallId = toolCallId
        self.result = result
        self.isError = isError
    }
}
