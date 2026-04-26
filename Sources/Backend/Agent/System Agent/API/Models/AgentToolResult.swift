import Foundation

struct AgentToolResult: Codable, Identifiable {
    let id: UUID
    let toolName: String
    let result: String
    let duration: TimeInterval
    let isError: Bool
    let warning: String?

    init(id: UUID = UUID(), toolName: String, result: String, duration: TimeInterval = 0, isError: Bool = false, warning: String? = nil) {
        self.id = id
        self.toolName = toolName
        self.result = result
        self.duration = duration
        self.isError = isError
        self.warning = warning
    }
}
