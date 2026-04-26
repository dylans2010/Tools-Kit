import Foundation

public struct AgentTaskStep: Codable, Identifiable {
    public let id: UUID
    public let description: String
    public var isCompleted: Bool
    public let priority: AgentTaskPriority

    public init(description: String, priority: AgentTaskPriority = .medium) {
        self.id = UUID()
        self.description = description
        self.isCompleted = false
        self.priority = priority
    }
}
