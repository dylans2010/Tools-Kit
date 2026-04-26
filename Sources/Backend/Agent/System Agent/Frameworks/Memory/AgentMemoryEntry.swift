import Foundation

public struct AgentMemoryEntry: Codable, Identifiable {
    public let id: UUID
    public let content: String
    public let tags: Set<String>
    public let timestamp: Date

    public init(content: String, tags: Set<String> = []) {
        self.id = UUID()
        self.content = content
        self.tags = tags
        self.timestamp = Date()
    }
}
