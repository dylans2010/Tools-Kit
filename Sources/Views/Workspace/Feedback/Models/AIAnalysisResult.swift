import Foundation

public struct AIAnalysisResult: Codable {
    public let summary: String
    public let suggestedCategory: FeedbackCategory?
    public let detectedDuplicates: [UUID]
    public let suggestedPriority: FeedbackPriority
    public let rootCauseHypothesis: String
    public let suggestedTags: [String]
    public let confidenceScore: Double
}
