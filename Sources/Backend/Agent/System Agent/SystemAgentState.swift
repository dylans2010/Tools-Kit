import Foundation

enum AgentType: String, CaseIterable, Codable {
    case system
    case jules
}

enum SystemAgentState {
    case idle
    case thinking
    case executingTool(name: String)
    case responding
    case completed
    case failed(Error)
}
