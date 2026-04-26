import Foundation

public struct AgentToolResult: Codable {
    public let toolCallId: String
    public let result: String
    public let isError: Bool

    public init(toolCallId: String, result: String, isError: Bool = false) {
        self.toolCallId = toolCallId
        self.result = result
        self.isError = isError
    }
}
