import Foundation

struct AgentContextWindow: Codable {
    var maxTokenEstimate: Int = 8_000

    static let `default` = AgentContextWindow()
}
