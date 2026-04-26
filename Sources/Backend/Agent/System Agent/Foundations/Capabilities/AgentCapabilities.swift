import Foundation

struct AgentCapabilities: Codable, OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }

    static let tools = AgentCapabilities(rawValue: 1 << 0)
    static let planning = AgentCapabilities(rawValue: 1 << 1)
    static let codeGeneration = AgentCapabilities(rawValue: 1 << 2)
    static let memory = AgentCapabilities(rawValue: 1 << 3)
    static let streaming = AgentCapabilities(rawValue: 1 << 4)
    static let automation = AgentCapabilities(rawValue: 1 << 5)
}
