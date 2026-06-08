import Foundation

public struct FeedbackNews: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let body: String
    public let date: Date
    public let type: NewsType

    public enum NewsType: String, Codable {
        case update, fix, announcement
    }
}
