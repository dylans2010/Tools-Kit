import Foundation

struct AgentAutomationStep: Codable, Identifiable, Sendable {
    let id: UUID
    let action: String
    let parameters: [String: AnyCodable]

    init(action: String, parameters: [String: AnyCodable] = [:]) {
        self.id = UUID()
        self.action = action
        self.parameters = parameters
    }
}
