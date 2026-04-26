import Foundation

struct AgentMemoryEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let role: String
    let content: String
    let toolsInvolved: [String]
    let tags: [String]
    let importance: Double
}
