import Foundation

enum AgentType: String, CaseIterable, Codable {
    case system
    case jules
}

enum SystemAgentState {
    case idle
    case thinking
    case executingTool(String)
    case responding
    case failed(Error)
}
