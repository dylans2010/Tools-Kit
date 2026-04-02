import Foundation

class TextSummarizerBackend: ObservableObject {
    @Published var inputText = ""
    @Published var summaryText = ""
    @Published var isLoading = false
    @Published var sentenceCount: Double = 3

    func summarize() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            summaryText = ""
            return
        }

        isLoading = true

        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let sentences = self.tokenizeSentences(text)
            if sentences.count <= Int(self.sentenceCount) {
                self.summaryText = text
            } else {
                self.summaryText = self.extractiveSummarize(sentences, topN: Int(self.sentenceCount))
            }
            self.isLoading = false
        }
    }

    private func tokenizeSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        let range = text.startIndex..<text.endIndex
        text.enumerateSubstrings(in: range, options: .bySentences) { (substring, _, _, _) in
            if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                sentences.append(s)
            }
        }
        return sentences
    }

    private func extractiveSummarize(_ sentences: [String], topN: Int) -> String {
        // Simple word frequency algorithm
        var wordCounts: [String: Int] = [:]
        let stopWords: Set<String> = ["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "is", "are", "was", "were", "of", "with"]

        for sentence in sentences {
            let words = sentence.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 3 && !stopWords.contains($0) }
            for word in words {
                wordCounts[word, default: 0] += 1
            }
        }

        var sentenceScores: [(Int, Double)] = []
        for (index, sentence) in sentences.enumerated() {
            let words = sentence.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 3 && !stopWords.contains($0) }
            var score: Double = 0
            for word in words {
                score += Double(wordCounts[word] ?? 0)
            }
            // Normalize by length to not favor extremely long sentences too much, but still keep informative ones
            sentenceScores.append((index, score / max(1, Double(words.count))))
        }

        // Sort by score and take top N
        let topIndices = sentenceScores.sorted { $0.1 > $1.1 }.prefix(topN).map { $0.0 }.sorted()

        return topIndices.map { sentences[$0] }.joined(separator: " ")
    }
}
