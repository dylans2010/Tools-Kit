import Foundation

public struct AgentToolCall: Codable, Identifiable {
    public let id: String
    public let name: String
    public let input: [String: AnyCodable]

    public init(id: String = UUID().uuidString, name: String, input: [String: AnyCodable]) {
        self.id = id
        self.name = name
        self.input = input
    }
}
