import Foundation

public struct Skill: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var content: String
    public var isActive: Bool
    public var createdAt: Date
    public var category: String
    public var version: String
    public var priority: Int

    public init(
        id: UUID = UUID(),
        name: String,
        content: String,
        isActive: Bool = true,
        createdAt: Date = Date(),
        category: String = "General",
        version: String = "1.0.0",
        priority: Int = 1
    ) {
        self.id = id
        self.name = name
        self.content = content
        self.isActive = isActive
        self.createdAt = createdAt
        self.category = category
        self.version = version
        self.priority = priority
    }
}
