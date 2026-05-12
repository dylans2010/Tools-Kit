import Foundation

struct AgentAPIResponse: Codable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let finishReason: String
    let tokenUsage: AgentTokenUsage
}
