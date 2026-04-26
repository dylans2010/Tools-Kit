import Foundation

public struct AgentAutomationStep: Codable, Identifiable {
    public let id: UUID
    public let action: String
    public let parameters: [String: AnyCodable]

    public init(action: String, parameters: [String: AnyCodable] = [:]) {
        self.id = UUID()
        self.action = action
        self.parameters = parameters
    }
}
