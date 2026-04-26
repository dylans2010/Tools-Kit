import Foundation

struct AgentAPIResponse: Codable, Identifiable {
    let id: UUID
    let text: String
    let finishReason: String
    let tokenUsage: AgentTokenUsage
}
