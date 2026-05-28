import SwiftUI

struct LoremIpsumGeneratorDevTool: DevTool {
    let id = "lorem-ipsum-generator"
    let name = "Lorem Ipsum Generator"
    let category = DevToolCategory.utilities
    let icon = "text.alignleft"
    let description = "Generate placeholder text in multiple styles"

    func render() -> some View {
        LoremIpsumGeneratorView()
    }
}

struct LoremIpsumGeneratorView: View {
    @StateObject private var viewModel = LoremIpsumGeneratorViewModel()

    var body: some View {
        Form {
            Section(header: Text("Configuration")) {
                Picker("Type", selection: $viewModel.generationType) {
                    Text("Paragraphs").tag(LoremType.paragraphs)
                    Text("Sentences").tag(LoremType.sentences)
                    Text("Words").tag(LoremType.words)
                    Text("List Items").tag(LoremType.listItems)
                }

                Stepper("Count: \(viewModel.count)", value: $viewModel.count, in: 1...50)

                Toggle("Start with 'Lorem ipsum...'", isOn: $viewModel.startClassic)

                Picker("Style", selection: $viewModel.textStyle) {
                    Text("Classic Latin").tag(LoremStyle.classic)
                    Text("Hipster").tag(LoremStyle.hipster)
                    Text("Tech").tag(LoremStyle.tech)
                }

                Button {
                    viewModel.generate()
                } label: {
                    Label("Generate", systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
            }

            Section(header: Text("Result")) {
                TextEditor(text: .constant(viewModel.output))
                    .frame(height: 200)
                    .font(.system(.body))

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = viewModel.output
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let html = "<html><body>\(viewModel.output.components(separatedBy: "\n\n").map { "<p>\($0)</p>" }.joined())</body></html>"
                        UIPasteboard.general.string = html
                    } label: {
                        Label("Copy as HTML", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section(header: Text("Statistics")) {
                LabeledContent("Characters", value: "\(viewModel.output.count)")
                LabeledContent("Words", value: "\(viewModel.output.split(separator: " ").count)")
                LabeledContent("Paragraphs", value: "\(viewModel.output.components(separatedBy: "\n\n").count)")
            }
        }
    }
}

enum LoremType { case paragraphs, sentences, words, listItems }
enum LoremStyle { case classic, hipster, tech }

class LoremIpsumGeneratorViewModel: ObservableObject {
    @Published var count = 3
    @Published var generationType = LoremType.paragraphs
    @Published var startClassic = true
    @Published var textStyle = LoremStyle.classic
    @Published var output = ""

    private let classicWords = ["lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit", "sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore", "magna", "aliqua", "enim", "ad", "minim", "veniam", "quis", "nostrud", "exercitation", "ullamco", "laboris", "nisi", "aliquip", "ex", "ea", "commodo", "consequat", "duis", "aute", "irure", "reprehenderit", "voluptate", "velit", "esse", "cillum", "fugiat", "nulla", "pariatur", "excepteur", "sint", "occaecat", "cupidatat", "proident", "sunt", "culpa", "qui", "officia", "deserunt", "mollit", "anim"]

    private let hipsterWords = ["artisan", "kombucha", "aesthetic", "sustainable", "vegan", "craft", "organic", "handcrafted", "curated", "bespoke", "locally", "sourced", "vintage", "minimalist", "ethical", "cold-brew", "avocado", "toast", "pour-over", "brunch"]

    private let techWords = ["API", "cloud", "server", "deploy", "container", "microservice", "pipeline", "frontend", "backend", "database", "scalable", "agile", "sprint", "DevOps", "CI/CD", "Kubernetes", "lambda", "serverless", "blockchain", "algorithm"]

    func generate() {
        let words: [String]
        switch textStyle {
        case .classic: words = classicWords
        case .hipster: words = hipsterWords
        case .tech: words = techWords
        }

        switch generationType {
        case .paragraphs:
            output = (0..<count).map { i in
                let sentCount = Int.random(in: 3...6)
                var para = (0..<sentCount).map { _ in makeSentence(words: words) }.joined(separator: " ")
                if i == 0 && startClassic && textStyle == .classic {
                    para = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " + para
                }
                return para
            }.joined(separator: "\n\n")
        case .sentences:
            output = (0..<count).map { i in
                if i == 0 && startClassic && textStyle == .classic {
                    return "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
                }
                return makeSentence(words: words)
            }.joined(separator: " ")
        case .words:
            var result = (0..<count).map { _ in words.randomElement()! }
            if startClassic && textStyle == .classic { result[0] = "Lorem" }
            output = result.joined(separator: " ")
        case .listItems:
            output = (0..<count).map { _ in
                "- " + makeSentence(words: words)
            }.joined(separator: "\n")
        }
    }

    private func makeSentence(words: [String]) -> String {
        let wordCount = Int.random(in: 5...12)
        let sentence = (0..<wordCount).map { _ in words.randomElement()! }.joined(separator: " ")
        return sentence.prefix(1).uppercased() + sentence.dropFirst() + "."
    }
}

#Preview {
    LoremIpsumGeneratorView()
}
