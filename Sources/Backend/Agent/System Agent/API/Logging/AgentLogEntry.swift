import Foundation

struct AgentLogEntry: Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let level: AgentLogLevel
    let message: String
    let metadata: [String: String]

    init(level: AgentLogLevel, message: String, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.timestamp = Date()
        self.level = level
        self.message = message
        self.metadata = metadata
    }
}
