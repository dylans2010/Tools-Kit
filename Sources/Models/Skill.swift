import Foundation

public struct Skill: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var content: String
    public var isActive: Bool
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, content: String, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.content = content
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
