import Foundation

struct AgentMemoryEntry: Codable, Identifiable {
    let id: UUID
    let content: String
    let tags: Set<String>
    let timestamp: Date

    init(content: String, tags: Set<String> = []) {
        self.id = UUID()
        self.content = content
        self.tags = tags
        self.timestamp = Date()
    }
}
