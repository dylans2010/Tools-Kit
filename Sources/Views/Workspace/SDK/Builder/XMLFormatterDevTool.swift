import SwiftUI

struct XMLFormatterDevTool: View, DevTool {
    let id = "xml-formatter"
    let name = "XML Formatter"
    let category = DevToolCategory.data
    let icon = "code.circle"
    let description = "Prettify and validate XML data"

    func render() -> some View {
        self
    }

    @StateObject private var viewModel = XMLFormatterViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "XML Formatter",
                description: "Clean up and format XML documents for better readability and structure validation.",
                icon: "code.circle"
            )
            .padding()

            Form {
                Section("Input XML") {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 150)
                        .font(.system(.caption, design: .monospaced))
                }

                Section("Output") {
                    Text(viewModel.output)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(8)
                        .textSelection(.enabled)

                    ExportPanel(content: viewModel.output, filename: "formatted.xml")
                }
            }
        }
    }
}

class XMLFormatterViewModel: ObservableObject {
    @Published var input = "<root><item id=\"1\">Test</item></root>" {
        didSet { format() }
    }
    @Published var output = ""

    private func format() {
        // Simple manual indentation logic for XML
        var result = ""
        var level = 0
        let tokens = input.replacingOccurrences(of: ">", with: ">\n").replacingOccurrences(of: "<", with: "\n<").components(separatedBy: .newlines)

        for token in tokens {
            let t = token.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { continue }

            if t.hasPrefix("</") { level -= 1 }
            result += String(repeating: "  ", count: max(0, level)) + t + "\n"
            if t.hasPrefix("<") && !t.hasPrefix("</") && !t.hasSuffix("/>") && !t.contains("</") {
                level += 1
            }
        }
        output = result
    }
}
