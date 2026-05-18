import SwiftUI

struct YAMLParserDevTool: DevTool {
    let id = "yaml-parser"
    let name = "YAML Parser"
    let category = DevToolCategory.data
    let icon = "doc.text.fill"
    let description = "Parse YAML into JSON"

    func render() -> some View {
        YAMLParserView()
    }
}

struct YAMLParserView: View {
    @StateObject private var viewModel = YAMLParserViewModel()

    var body: some View {
        Form {
            Section("YAML Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 150)
                    .font(.monospaced(.body)())
            }

            Section("Parsed JSON (Simple)") {
                Text(viewModel.outputText)
                    .font(.monospaced(.body)())
                    .textSelection(.enabled)

                Text("Note: Basic line-based YAML parsing implementation.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

class YAMLParserViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            parse()
        }
    }
    @Published var outputText = ""

    private func parse() {
        var dict: [String: String] = [:]
        let lines = inputText.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: ":")
            if parts.count == 2 {
                dict[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }

        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            outputText = String(data: data, encoding: .utf8) ?? "{}"
        } else {
            outputText = "{}"
        }
    }
}
