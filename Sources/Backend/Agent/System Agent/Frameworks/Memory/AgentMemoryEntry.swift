import Foundation

struct AgentMemoryEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let key: String
    let category: String?
    let value: AnyCodable
    let content: String
    let tags: Set<String>
    let timestamp: Date

    init(
        key: String,
        category: String? = nil,
        value: AnyCodable,
        content: String,
        tags: Set<String> = [],
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.key = key
        self.category = category
        self.value = value
        self.content = content
        self.tags = tags
        self.timestamp = timestamp
    }

    init(content: String, tags: Set<String> = []) {
        self.id = UUID()
        self.key = content
        self.category = tags.first
        self.value = AnyCodable(content)
        self.content = content
        self.tags = tags
        self.timestamp = Date()
    }
}
