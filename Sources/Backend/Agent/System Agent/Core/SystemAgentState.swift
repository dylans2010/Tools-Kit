import Foundation

enum AgentType: String, CaseIterable, Codable, Sendable {
    case system
    case jules
}

enum SystemAgentState: Sendable {
    case idle
    case thinking
    case executingTool(name: String)
    case responding
    case completed
    case failed(Error)
}
