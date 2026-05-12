import Foundation

struct AgentToolCall: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let input: [String: AnyCodable]

    init(id: String = UUID().uuidString, name: String, input: [String: AnyCodable]) {
        self.id = id
        self.name = name
        self.input = input
    }
}
