import Foundation

struct AgentContextSnapshot: Codable {
    let id: UUID
    let timestamp: Date
    let context: AgentContext

    init(context: AgentContext) {
        self.id = UUID()
        self.timestamp = Date()
        self.context = context
    }
}
