import Foundation

struct AgentContextSnapshot: Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let context: AgentContext

    init(context: AgentContext) {
        self.id = UUID()
        self.timestamp = Date()
        self.context = context
    }
}
