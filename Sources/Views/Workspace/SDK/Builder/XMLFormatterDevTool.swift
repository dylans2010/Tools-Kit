import SwiftUI

struct XMLFormatterDevTool: DevTool {
    let id = "xml-formatter"
    let name = "XML Formatter"
    let category = DevToolCategory.data
    let icon = "chevron.left.slash.chevron.right"
    let description = "Prettify and format XML strings"

    func render() -> some View {
        XMLFormatterView()
    }
}

struct XMLFormatterView: View {
    @StateObject private var viewModel = XMLFormatterViewModel()

    var body: some View {
        Form {
            Section("XML Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 150)
                    .font(.monospaced(.body)())
            }

            Section("Formatted Output") {
                Text(viewModel.outputText)
                    .font(.monospaced(.body)())
                    .textSelection(.enabled)

                Text("Note: Basic structural XML indentation.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

class XMLFormatterViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            format()
        }
    }
    @Published var outputText = ""

    private func format() {
        var result = ""
        var level = 0
        let tokens = inputText.replacingOccurrences(of: ">", with: ">\n").replacingOccurrences(of: "<", with: "\n<").components(separatedBy: .newlines)

        for token in tokens {
            let trimmed = token.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if trimmed.hasPrefix("</") {
                level -= 1
            }

            result += String(repeating: "  ", count: max(0, level)) + trimmed + "\n"

            if trimmed.hasPrefix("<") && !trimmed.hasPrefix("</") && !trimmed.hasSuffix("/>") && !trimmed.hasPrefix("<?") {
                level += 1
            }
        }
        outputText = result
    }
}
