import Foundation

public struct FeedbackActivity: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let action: String
    public let actor: String
}
