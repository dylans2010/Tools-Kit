import SwiftUI

struct WordCounterDevTool: DevTool {
    let id = "word-counter"
    let name = "Word Counter"
    let category: DevToolCategory = .utilities
    let icon = "textformat.123"
    let description = "Count words, characters, sentences, and paragraphs"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Paste text to analyze") { input in
            let words = input.split { $0.isWhitespace }.count
            let chars = input.count
            let sentences = input.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
            let paragraphs = input.components(separatedBy: "\n\n").filter { !$0.isEmpty }.count
            return "Words: \(words)\nCharacters: \(chars)\nSentences: \(sentences)\nParagraphs: \(paragraphs)\nReading Time: ~\(max(1, words / 200)) min"
        }
    }
}
