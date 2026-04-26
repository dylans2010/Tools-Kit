import Foundation

struct AgentDemoStep: Identifiable, Codable {
    let id: UUID
    let index: Int
    let instruction: String
}
