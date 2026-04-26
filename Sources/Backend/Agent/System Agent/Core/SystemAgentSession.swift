import Foundation

public final class SystemAgentSession: Codable, Identifiable {
    public let id: String
    public let createdAt: Date
    public var updatedAt: Date
    public var messages: [SystemAgentMessage]
    public var metadata: [String: String]

    public init(id: String = UUID().uuidString) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
        self.metadata = [:]
    }

    public func addMessage(_ message: SystemAgentMessage) {
        messages.append(message)
        updatedAt = Date()
    }
}
