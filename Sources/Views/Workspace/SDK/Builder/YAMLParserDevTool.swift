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
        Form {
            Section(header: Text("YAML Input")) {
                TextEditor(text: $viewModel.input)
                    .frame(height: 150)
                    .font(.system(.caption, design: .monospaced))
            }

            Section(header: Text("JSON Output")) {
                ScrollView {
                    Text(viewModel.output)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(8)
                .frame(minHeight: 200)

                HStack {
                    Button {
                        UIPasteboard.general.string = viewModel.output
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("converted.json")
                        try? viewModel.output.write(to: fileURL, atomically: true, encoding: .utf8)
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
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

#Preview {
    YAMLParserView()
}
