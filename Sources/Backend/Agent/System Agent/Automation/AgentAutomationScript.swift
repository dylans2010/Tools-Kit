import Foundation

struct AgentAutomationScript: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let author: String
    let version: String
    let steps: [AgentAutomationStep]
    let requiredCapabilities: AgentCapabilities
    let estimatedDuration: TimeInterval
    let tags: [String]
}
