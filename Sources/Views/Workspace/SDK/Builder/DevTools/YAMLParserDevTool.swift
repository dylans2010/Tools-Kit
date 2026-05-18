import SwiftUI

struct YAMLParserTool: DevTool {
    let id = UUID()
    let name = "YAML Parser"
    let category: DevToolCategory = .data
    let icon = "doc.plaintext"
    let description = "Parse and validate YAML-like structured data"
    func render() -> some View { YAMLParserDevToolView() }
}

struct YAMLParserDevToolView: View {
    @State private var input = "name: John\nage: 30\ncity: New York\nactive: true"
    @State private var pairs: [(String, String)] = []
    var body: some View {
        Form {
            Section("YAML Input") {
                TextEditor(text: $input).frame(minHeight: 120).font(.system(.body, design: .monospaced))
            }
            Section {
                Button("Parse") { parse() }
                    .disabled(input.isEmpty)
            }
            if !pairs.isEmpty {
                Section("Parsed (\(pairs.count) entries)") {
                    ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                        LabeledContent {
                            Text(pair.1).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                        } label: {
                            Text(pair.0).font(.system(.caption, design: .monospaced)).bold()
                        }
                    }
                }
            }
        }
        .navigationTitle("YAML Parser")
    }
    private func parse() {
        pairs = input.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }
            let parts = trimmed.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            return (String(parts[0]).trimmingCharacters(in: .whitespaces),
                    String(parts[1]).trimmingCharacters(in: .whitespaces))
        }
    }
}
