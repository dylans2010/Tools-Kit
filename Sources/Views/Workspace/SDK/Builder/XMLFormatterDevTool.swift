import SwiftUI

struct XMLFormatterDevTool: DevTool {
    let id = "xml-formatter"
    let name = "XML Formatter"
    let category = DevToolCategory.data
    let icon = "code.circle"
    let description = "Prettify and validate XML data"

    func render() -> some View {
        XMLFormatterDevToolView()
    }
}

struct XMLFormatterDevToolView: View {
    @StateObject private var viewModel = XMLFormatterViewModel()

    var body: some View {
        Form {
            Section(header: Text("Input XML")) {
                TextEditor(text: $viewModel.input)
                    .frame(height: 150)
                    .font(.system(.caption, design: .monospaced))
            }

            Section(header: Text("Output")) {
                ScrollView {
                    Text(viewModel.output)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(8)

                HStack {
                    Button {
                        UIPasteboard.general.string = viewModel.output
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("formatted.xml")
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

#Preview {
    XMLFormatterDevToolView()
}
