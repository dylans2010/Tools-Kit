import Foundation

public struct AgentAutomationScript: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let steps: [AgentAutomationStep]

    public init(name: String, steps: [AgentAutomationStep]) {
        self.id = UUID()
        self.name = name
        self.steps = steps
    }
}
