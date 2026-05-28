import SwiftUI

struct TextCaseConverterDevTool: DevTool {
    let id = "text-case-converter"
    let name = "Text Case Converter"
    let category = DevToolCategory.utilities
    let icon = "textformat.abc"
    let description = "Transform text between all common case formats"

    func render() -> some View {
        TextCaseConverterView()
    }
}

struct TextCaseConverterView: View {
    @StateObject private var viewModel = TextCaseConverterViewModel()

    var body: some View {
        Form {
            Section(header: Text("Input")) {
                TextEditor(text: $viewModel.input)
                    .frame(height: 80)
                HStack {
                    Button("Paste") {
                        if let text = UIPasteboard.general.string { viewModel.input = text }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                    Button("Clear") { viewModel.input = "" }
                        .buttonStyle(.bordered).controlSize(.small)
                    Spacer()
                    Text("\(viewModel.input.count) chars")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Case Conversions")) {
                VStack(alignment: .leading, spacing: 10) {
                    caseRow(title: "UPPERCASE", value: viewModel.input.uppercased())
                    caseRow(title: "lowercase", value: viewModel.input.lowercased())
                    caseRow(title: "Title Case", value: viewModel.input.capitalized)
                    caseRow(title: "Sentence case", value: viewModel.toSentenceCase())
                    caseRow(title: "snake_case", value: viewModel.toSnakeCase())
                    caseRow(title: "SCREAMING_SNAKE", value: viewModel.toSnakeCase().uppercased())
                    caseRow(title: "camelCase", value: viewModel.toCamelCase())
                    caseRow(title: "PascalCase", value: viewModel.toPascalCase())
                    caseRow(title: "kebab-case", value: viewModel.toKebabCase())
                    caseRow(title: "dot.case", value: viewModel.toDotCase())
                    caseRow(title: "path/case", value: viewModel.toPathCase())
                    caseRow(title: "aLtErNaTiNg", value: viewModel.toAlternatingCase())
                }
            }

            Section(header: Text("Statistics")) {
                LabeledContent("Characters", value: "\(viewModel.input.count)")
                LabeledContent("Words", value: "\(viewModel.wordCount)")
                LabeledContent("Lines", value: "\(viewModel.lineCount)")
                LabeledContent("Unique chars", value: "\(Set(viewModel.input).count)")
            }

            Section(header: Text("Text Operations")) {
                HStack(spacing: 8) {
                    Button("Reverse") { viewModel.input = String(viewModel.input.reversed()) }
                        .buttonStyle(.bordered).controlSize(.small)
                    Button("Trim") { viewModel.input = viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .buttonStyle(.bordered).controlSize(.small)
                    Button("Remove Spaces") { viewModel.input = viewModel.input.replacingOccurrences(of: " ", with: "") }
                        .buttonStyle(.bordered).controlSize(.small)
                    Button("Squeeze") { viewModel.input = viewModel.input.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) }
                        .buttonStyle(.bordered).controlSize(.small)
                }
            }
        }
    }

    private func caseRow(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption2.bold()).foregroundStyle(.secondary)
                Text(value).font(.system(.caption, design: .monospaced)).textSelection(.enabled).lineLimit(2)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = value
            } label: {
                Image(systemName: "doc.on.doc").font(.caption2)
            }
            .buttonStyle(.plain)
        }
    }
}

class TextCaseConverterViewModel: ObservableObject {
    @Published var input = "Hello World Example"

    var wordCount: Int { input.split(separator: " ").count }
    var lineCount: Int { input.components(separatedBy: .newlines).count }

    private func splitWords() -> [String] {
        var words: [String] = []
        let pattern = "([A-Z][a-z]+|[A-Z]+(?=[A-Z]|$)|[a-z]+|[0-9]+)"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            let matches = regex.matches(in: input, range: range)
            words = matches.compactMap { Range($0.range, in: input).map { String(input[$0]) } }
        }
        if words.isEmpty {
            words = input.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        }
        return words
    }

    func toSnakeCase() -> String {
        splitWords().map { $0.lowercased() }.joined(separator: "_")
    }

    func toCamelCase() -> String {
        let words = splitWords()
        guard let first = words.first else { return "" }
        return first.lowercased() + words.dropFirst().map { $0.capitalized }.joined()
    }

    func toPascalCase() -> String {
        splitWords().map { $0.capitalized }.joined()
    }

    func toKebabCase() -> String {
        splitWords().map { $0.lowercased() }.joined(separator: "-")
    }

    func toDotCase() -> String {
        splitWords().map { $0.lowercased() }.joined(separator: ".")
    }

    func toPathCase() -> String {
        splitWords().map { $0.lowercased() }.joined(separator: "/")
    }

    func toSentenceCase() -> String {
        guard let first = input.first else { return "" }
        return first.uppercased() + input.dropFirst().lowercased()
    }

    func toAlternatingCase() -> String {
        String(input.enumerated().map { $0.offset % 2 == 0 ? Character($0.element.lowercased()) : Character($0.element.uppercased()) })
    }
}

#Preview {
    TextCaseConverterView()
}
