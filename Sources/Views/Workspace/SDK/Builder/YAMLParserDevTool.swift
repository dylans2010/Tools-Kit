import SwiftUI

struct YAMLParserDevTool: DevTool {
    let id = "yaml-parser"
    let name = "YAML Parser"
    let category = DevToolCategory.data
    let icon = "text.badge.star"
    let description = "Parse YAML and convert to JSON"

    func render() -> some View {
        YAMLParserView()
    }
}

struct YAMLParserView: View {
    @StateObject private var viewModel = YAMLParserViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "YAML Parser",
                description: "Inspect YAML documents and convert them to JSON format for better compatibility.",
                icon: "text.badge.star"
            )
            .padding()

            Form {
                Section("YAML Input") {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 150)
                        .font(.system(.caption, design: .monospaced))
                }

                Section("JSON Output") {
                    JSONView(json: viewModel.output)
                        .frame(minHeight: 200)

                    ExportPanel(content: viewModel.output, filename: "converted.json")
                }
            }
        }
    }
}

class YAMLParserViewModel: ObservableObject {
    @Published var input = "name: SDK\nversion: 2.0\nfeatures:\n  - monitoring\n  - debugging" {
        didSet { parse() }
    }
    @Published var output = ""

    private func parse() {
        // Simple manual YAML-to-JSON conversion for basic structures
        // In a real app, use a YAMLLib
        var result = "{\n"
        let lines = input.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let val = parts[1].trimmingCharacters(in: .whitespaces)
                result += "  \"\(key)\": \"\(val)\",\n"
            }
        }
        if result.hasSuffix(",\n") {
            result.removeLast(2)
            result += "\n"
        }
        result += "}"
        output = result
    }
}
