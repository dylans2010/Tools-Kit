import Foundation

public struct AgentDemoScript: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let steps: [AgentDemoStep]

    public init(name: String, steps: [AgentDemoStep]) {
        self.id = UUID()
        self.name = name
        self.steps = steps
    }
}
