import Foundation

struct AgentAutomationResult: Codable, Sendable {
    let scriptId: UUID
    let success: Bool
    let output: String
    let error: String?
}
