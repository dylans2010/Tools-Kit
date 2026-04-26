import Foundation

struct AgentAutomationScript: Codable, Identifiable {
    let id: UUID
    let name: String
    let steps: [AgentAutomationStep]

    init(name: String, steps: [AgentAutomationStep]) {
        self.id = UUID()
        self.name = name
        self.steps = steps
    }
}
