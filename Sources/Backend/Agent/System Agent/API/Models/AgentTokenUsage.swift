import Foundation

struct AgentTokenUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}
