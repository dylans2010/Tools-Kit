import Foundation

struct AgentTaskStep: Codable, Identifiable {
    let id: UUID
    var title: String
    var priority: AgentTaskPriority
    var completed: Bool

    init(id: UUID = UUID(), title: String, priority: AgentTaskPriority = .normal, completed: Bool = false) {
        self.id = id
        self.title = title
        self.priority = priority
        self.completed = completed
    }
}
