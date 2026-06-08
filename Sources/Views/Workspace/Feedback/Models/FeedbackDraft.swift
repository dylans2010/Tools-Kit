import Foundation

public struct FeedbackDraft: Identifiable, Codable {
    public let id: UUID
    public var report: FeedbackReport
    public var lastSaved: Date
    public var version: Int
}
