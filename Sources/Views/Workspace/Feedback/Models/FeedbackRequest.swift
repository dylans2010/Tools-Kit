import Foundation

public struct FeedbackRequest: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public var votes: Int
    public var hasVoted: Bool
    public let category: FeedbackCategory
    public let status: String
}
