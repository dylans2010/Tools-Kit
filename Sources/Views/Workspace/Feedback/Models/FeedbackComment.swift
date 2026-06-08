import Foundation

public struct FeedbackComment: Identifiable, Codable {
    public let id: UUID
    public let author: String
    public let text: String
    public let timestamp: Date
    public let isSystem: Bool
}
