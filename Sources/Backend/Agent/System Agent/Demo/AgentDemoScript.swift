import Foundation

struct AgentDemoScript: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let estimatedDuration: TimeInterval
    let steps: [AgentDemoStep]
    let requiredCapabilities: [String]
}
