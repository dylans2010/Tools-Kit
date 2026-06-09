import Foundation

public struct FeedbackReport: Identifiable, Codable {
    public let id: UUID
    public var category: FeedbackCategory
    public var status: FeedbackStatus
    public var priority: FeedbackPriority
    public var summary: String
    public var description: String
    public var expectedBehavior: String?
    public var actualBehavior: String?
    public var reproductionSteps: [String]
    public var dynamicAnswers: [String: String]
    public var frequency: String?
    public var impactScore: Int // 1-10
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date
    public var resolvedAt: Date?

    public var diagnostics: DiagnosticsData?
    public var aiAnalysis: AIAnalysisResult?
    public var attachments: [FeedbackAttachment]
    public var history: [FeedbackActivity]
    public var comments: [FeedbackComment]

    public init(id: UUID = UUID(), category: FeedbackCategory = .other) {
        self.id = id
        self.category = category
        self.status = .draft
        self.priority = .medium
        self.summary = ""
        self.description = ""
        self.reproductionSteps = []
        self.dynamicAnswers = [:]
        self.impactScore = 5
        self.tags = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.attachments = []
        self.history = []
        self.comments = []
    }
}
