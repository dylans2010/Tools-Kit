import Foundation

class SuggestionEngine {
    func generateSuggestions(text: String, analysis: TextAnalysis) -> [Suggestion] {
        guard !text.isEmpty else { return [] }

        var suggestions: [Suggestion] = []

        // Context-aware ranking based on analysis
        if analysis.score < 0.7 {
            suggestions.append(Suggestion(
                originalText: text,
                suggestedText: "Clarify: " + text,
                category: .clarity,
                score: 0.9
            ))
        }

        if analysis.formality == "Informal" && analysis.sentiment == "Professional" {
             suggestions.append(Suggestion(
                originalText: text,
                suggestedText: "Polished: " + text,
                category: .tone,
                score: 0.85
            ))
        }

        // Limit to 3 suggestions as per requirements
        return Array(suggestions.prefix(3))
    }

    func rankSuggestions(_ suggestions: [Suggestion]) -> [Suggestion] {
        return suggestions.sorted(by: { $0.score > $1.score })
    }
}
