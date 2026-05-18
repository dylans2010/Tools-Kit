import SwiftUI

struct LoremIpsumGeneratorTool: DevTool {
    let id = UUID()
    let name = "Lorem Ipsum Generator"
    let category: DevToolCategory = .utilities
    let icon = "text.justify"
    let description = "Generate placeholder text"
    func render() -> some View { LoremIpsumGeneratorDevToolView() }
}

struct LoremIpsumGeneratorDevToolView: View {
    @State private var paragraphs: Double = 3
    @State private var generated = ""
    @State private var mode = 0

    private let words = ["lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit",
        "sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore", "magna",
        "aliqua", "enim", "ad", "minim", "veniam", "quis", "nostrud", "exercitation", "ullamco",
        "laboris", "nisi", "aliquip", "ex", "ea", "commodo", "consequat", "duis", "aute", "irure",
        "in", "reprehenderit", "voluptate", "velit", "esse", "cillum", "fugiat", "nulla",
        "pariatur", "excepteur", "sint", "occaecat", "cupidatat", "non", "proident", "sunt",
        "culpa", "qui", "officia", "deserunt", "mollit", "anim", "id", "est", "laborum"]

    var body: some View {
        Form {
            Section("Configuration") {
                Picker("Mode", selection: $mode) {
                    Text("Paragraphs").tag(0)
                    Text("Words").tag(1)
                    Text("Sentences").tag(2)
                }
                .pickerStyle(.segmented)
                LabeledContent("Count: \(Int(paragraphs))") {
                    Slider(value: $paragraphs, in: 1...20, step: 1)
                }
                Button("Generate") { generate() }
            }
            if !generated.isEmpty {
                Section("Output (\(generated.count) chars)") {
                    Text(generated)
                        .font(.body)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Lorem Ipsum Generator")
    }

    private func generate() {
        let count = Int(paragraphs)
        switch mode {
        case 0:
            generated = (0..<count).map { _ in generateParagraph() }.joined(separator: "\n\n")
        case 1:
            generated = (0..<count).map { _ in words.randomElement() ?? "lorem" }.joined(separator: " ")
        case 2:
            generated = (0..<count).map { _ in generateSentence() }.joined(separator: " ")
        default:
            break
        }
    }

    private func generateSentence() -> String {
        let length = Int.random(in: 6...15)
        let sentenceWords = (0..<length).map { _ in words.randomElement() ?? "lorem" }
        var sentence = sentenceWords.joined(separator: " ")
        sentence = sentence.prefix(1).uppercased() + sentence.dropFirst()
        return sentence + "."
    }

    private func generateParagraph() -> String {
        let sentenceCount = Int.random(in: 4...8)
        return (0..<sentenceCount).map { _ in generateSentence() }.joined(separator: " ")
    }
}
