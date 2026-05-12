import Foundation

struct AIResponse: Codable, Sendable {
    let result: String
    let suggestions: [Suggestion]
    let analysis: TextAnalysis
}
