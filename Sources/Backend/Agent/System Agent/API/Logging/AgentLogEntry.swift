import Foundation

struct AgentLogEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let level: AgentLogLevel
    let component: String
    let message: String
}
