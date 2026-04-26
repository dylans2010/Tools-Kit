import Foundation

struct AgentToolCall: Codable, Identifiable {
    let id: UUID
    let name: String
    let input: [String: String]

    init(id: UUID = UUID(), name: String, input: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.input = input
    }
}
