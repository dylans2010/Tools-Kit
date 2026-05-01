import Foundation

class TextAnalyzer {
    static func countWords(in text: String) -> Int {
        return text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    static func extractSentences(from text: String) -> [String] {
        return text.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}
