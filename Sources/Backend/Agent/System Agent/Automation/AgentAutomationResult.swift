import Foundation

public struct AgentAutomationResult: Codable {
    public let scriptId: UUID
    public let success: Bool
    public let output: String
    public let error: String?
}
