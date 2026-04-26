import Foundation

struct AgentAutomationResult: Codable {
    let scriptId: UUID
    let success: Bool
    let output: String
    let error: String?
}
