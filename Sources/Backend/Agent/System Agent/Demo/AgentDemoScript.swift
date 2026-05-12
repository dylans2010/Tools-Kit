import Foundation

struct AgentDemoScript: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let steps: [AgentDemoStep]

    init(name: String, steps: [AgentDemoStep]) {
        self.id = UUID()
        self.name = name
        self.steps = steps
    }
}
