import Foundation

public struct AgentLogEntry: Codable {
    public let id: UUID
    public let timestamp: Date
    public let level: AgentLogLevel
    public let message: String
    public let metadata: [String: String]

    public init(level: AgentLogLevel, message: String, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.timestamp = Date()
        self.level = level
        self.message = message
        self.metadata = metadata
    }
}
