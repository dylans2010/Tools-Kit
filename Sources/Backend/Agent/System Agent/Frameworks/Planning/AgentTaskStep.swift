import Foundation

struct AgentTaskStep: Codable, Identifiable {
    let id: UUID
    let description: String
    var isCompleted: Bool
    let priority: AgentTaskPriority

    init(description: String, priority: AgentTaskPriority = .medium) {
        self.id = UUID()
        self.description = description
        self.isCompleted = false
        self.priority = priority
    }
}
