import Foundation

public struct AgentContextSnapshot: Codable {
    public let id: UUID
    public let timestamp: Date
    public let context: AgentContext

    public init(context: AgentContext) {
        self.id = UUID()
        self.timestamp = Date()
        self.context = context
    }
}
