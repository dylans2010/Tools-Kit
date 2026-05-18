import SwiftUI

struct TextCaseConverterTool: DevTool {
    let id = UUID()
    let name = "Text Case Converter"
    let category: DevToolCategory = .utilities
    let icon = "textformat.alt"
    let description = "Convert text between cases"
    func render() -> some View { TextCaseConverterDevToolView() }
}

struct TextCaseConverterDevToolView: View {
    @State private var input = ""
    @State private var results: [(String, String)] = []

    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $input).frame(minHeight: 80).font(.system(.body, design: .monospaced))
                Button("Convert") { convert() }
                    .disabled(input.isEmpty)
            }
            if !results.isEmpty {
                Section("Results") {
                    ForEach(results, id: \.0) { name, value in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name).font(.caption.bold()).foregroundStyle(.accent)
                            Text(value).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Text Case Converter")
    }

    private func convert() {
        let words = input.split(separator: " ").map(String.init)
        results = [
            ("UPPERCASE", input.uppercased()),
            ("lowercase", input.lowercased()),
            ("Title Case", words.map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }.joined(separator: " ")),
            ("Sentence case", input.prefix(1).uppercased() + input.dropFirst().lowercased()),
            ("camelCase", words.enumerated().map { $0.offset == 0 ? $0.element.lowercased() : $0.element.prefix(1).uppercased() + $0.element.dropFirst().lowercased() }.joined()),
            ("PascalCase", words.map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }.joined()),
            ("snake_case", words.map { $0.lowercased() }.joined(separator: "_")),
            ("SCREAMING_SNAKE", words.map { $0.uppercased() }.joined(separator: "_")),
            ("kebab-case", words.map { $0.lowercased() }.joined(separator: "-")),
            ("dot.case", words.map { $0.lowercased() }.joined(separator: ".")),
        ]
    }
}
