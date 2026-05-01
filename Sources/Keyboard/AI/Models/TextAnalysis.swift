import Foundation

struct TextAnalysis: Codable {
    let intent: String
    let sentiment: String
    let urgency: String
    let formality: String
    let score: Double
}
