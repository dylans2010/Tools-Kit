import Foundation

struct WritingStats {
    var wordCount: Int = 0
    var charCount: Int = 0
    var sentenceCount: Int = 0
    var paragraphCount: Int = 0
    var avgWordsPerSentence: Double = 0.0
    var avgWordsPerParagraph: Double = 0.0
    var readabilityScore: Double = 0.0
    var gradeLevel: String = "N/A"
    var complexWordCount: Int = 0
    var uniqueWordCount: Int = 0
    var vocabularyRichness: Double = 0.0
}

struct ArgumentAnalysis: Codable {
    var strengthScore: Double
    var feedback: String
    var logicGaps: [String]
    var persuasiveElements: [String]
}

struct AmbiguityAnalysis: Codable {
    var confusionScore: Double
    var unclearSections: [String]
    var suggestions: [String]
}

struct StructureFlow: Codable {
    var balanceScore: Double
    var flowFeedback: String
    var paragraphStats: [Double] // words per paragraph distribution
}

struct ToneAnalysis {
    var primary: String = "Neutral"
    var confidence: Double = 0.0
    var positive: Double = 0.0
    var negative: Double = 0.0
    var neutral: Double = 0.0
    var analytical: Double = 0.0
    var confident: Double = 0.0
    var tentative: Double = 0.0
}

struct SentenceLengthAnalysis {
    var short: Int = 0
    var medium: Int = 0
    var long: Int = 0
    var average: Double = 0.0
}

struct WordComplexity {
    var simple: Int = 0
    var moderate: Int = 0
    var complex: Int = 0
    var averageSyllables: Double = 0.0
    var complexityScore: Double = 0.0
}

struct WordFrequencyItem: Identifiable {
    let id = UUID()
    var word: String
    var count: Int
    var percentage: Double
}

struct OverusedWord: Identifiable {
    let id = UUID()
    var word: String
    var count: Int
    var percentage: Double
    var suggestions: [String]
}

struct GrammarIssue: Identifiable {
    let id = UUID()
    var word: String
    var suggestion: String
    var severity: String
    var type: String
    var message: String
    var context: String
}

struct ImprovementSuggestion: Identifiable {
    let id = UUID()
    var category: String
    var suggestion: String
    var impact: String
    var icon: String
}

struct AnalyticsChatMessage: Identifiable {
    let id = UUID()
    var role: String
    var content: String
    var timestamp: Date = Date()
}

struct KeywordInsight: Identifiable {
    let id = UUID()
    var word: String
    var count: Int
    var density: Double
}

struct SearchMatch: Identifiable {
    let id = UUID()
    var index: Int
    var text: String
    var contextSnippet: String
}

struct PlagiarismResult: Codable {
    var overallScore: Double
    var riskLevel: String
    var matches: [PlagiarismMatch]
    var checkedSentences: Int
    var totalSentences: Int
}

struct PlagiarismMatch: Identifiable, Codable {
    let id = UUID()
    var text: String
    var similarity: Double
    var source: String
    var matchType: String

    enum CodingKeys: String, CodingKey {
        case text, similarity, source, matchType
    }
}
