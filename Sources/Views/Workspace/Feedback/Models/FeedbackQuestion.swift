import Foundation

public enum FeedbackQuestionType: String, Codable {
    case text
    case longText
    case toggle
    case singleChoice
}

public struct FeedbackQuestion: Identifiable, Codable {
    public let id: String
    public let title: String
    public let type: FeedbackQuestionType
    public let placeholder: String?
    public let options: [String]?
    public let isRequired: Bool

    public init(id: String, title: String, type: FeedbackQuestionType, placeholder: String? = nil, options: [String]? = nil, isRequired: Bool = false) {
        self.id = id
        self.title = title
        self.type = type
        self.placeholder = placeholder
        self.options = options
        self.isRequired = isRequired
    }
}
