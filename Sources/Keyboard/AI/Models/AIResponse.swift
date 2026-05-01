import Foundation

struct AIResponse: Codable {
    let result: String
    let suggestions: [Suggestion]
    let analysis: TextAnalysis
}
