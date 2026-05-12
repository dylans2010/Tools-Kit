import Foundation

struct Suggestion: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let originalText: String
    let suggestedText: String
    let category: SuggestionCategory
    let score: Double

    init(id: UUID = UUID(), originalText: String, suggestedText: String, category: SuggestionCategory, score: Double) {
        self.id = id
        self.originalText = originalText
        self.suggestedText = suggestedText
        self.category = category
        self.score = score
    }
}

enum SuggestionCategory: String, Codable, Sendable {
    case grammar = "Grammar"
    case clarity = "Clarity"
    case tone = "Tone"
    case rewrite = "Rewrite"
    case reply = "Smart Reply"
}
