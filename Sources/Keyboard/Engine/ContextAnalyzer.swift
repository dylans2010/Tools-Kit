import Foundation

class ContextAnalyzer {
    func analyze(text: String) -> TextAnalysis {
        guard !text.isEmpty else {
            return TextAnalysis(intent: "Unknown", sentiment: "Neutral", urgency: "Low", formality: "Standard", score: 0.0)
        }

        // Lightweight heuristic-based analysis
        let intent = detectIntent(text)
        let sentiment = detectSentiment(text)
        let urgency = detectUrgency(text)
        let formality = detectFormality(text)

        return TextAnalysis(
            intent: intent,
            sentiment: sentiment,
            urgency: urgency,
            formality: formality,
            score: calculateConfidenceScore(text)
        )
    }

    private func detectIntent(_ text: String) -> String {
        if text.contains("?") { return "Question" }
        if text.lowercased().contains("please") { return "Request" }
        return "Statement"
    }

    private func detectSentiment(_ text: String) -> String {
        let positive = ["happy", "good", "great", "thanks", "excellent"]
        let negative = ["bad", "sad", "issue", "error", "problem"]

        let lowerText = text.lowercased()
        if positive.contains(where: { lowerText.contains($0) }) { return "Positive" }
        if negative.contains(where: { lowerText.contains($0) }) { return "Negative" }
        return "Neutral"
    }

    private func detectUrgency(_ text: String) -> String {
        let urgentKeys = ["asap", "urgent", "deadline", "emergency", "immediately"]
        if urgentKeys.contains(where: { text.lowercased().contains($0) }) { return "High" }
        return "Normal"
    }

    private func detectFormality(_ text: String) -> String {
        let formalKeys = ["sincerely", "dear", "regarding", "concerning"]
        if formalKeys.contains(where: { text.lowercased().contains($0) }) { return "Formal" }
        return "Informal"
    }

    private func calculateConfidenceScore(_ text: String) -> Double {
        return min(Double(text.count) / 100.0, 1.0)
    }
}
