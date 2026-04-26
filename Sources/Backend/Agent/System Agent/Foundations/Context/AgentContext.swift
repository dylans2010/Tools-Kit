import Foundation

struct AgentContext: Codable {
    var sessionID: UUID = UUID()
    var metadata: [String: String] = [:]
}
