import SwiftUI

struct XMLFormatterTool: DevTool {
    let id = UUID()
    let name = "XML Formatter"
    let category: DevToolCategory = .data
    let icon = "doc.text.magnifyingglass"
    let description = "Format and validate XML documents"
    func render() -> some View { XMLFormatterDevToolView() }
}

struct XMLFormatterDevToolView: View {
    @State private var input = ""
    @State private var output = ""
    @State private var errorMsg: String?
    var body: some View {
        Form {
            Section("XML Input") {
                TextEditor(text: $input).frame(minHeight: 120).font(.system(.caption, design: .monospaced))
            }
            Section {
                Button("Format") { format() }
                    .disabled(input.isEmpty)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            if !output.isEmpty {
                Section("Formatted") {
                    Text(output).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("XML Formatter")
    }
    private func format() {
        errorMsg = nil
        guard let data = input.data(using: .utf8) else { errorMsg = "Invalid input"; return }
        do {
            let doc = try XMLDocument(data: data, options: [.nodePrettyPrint])
            output = doc.xmlString(options: [.nodePrettyPrint])
        } catch {
            var indentLevel = 0
            var formatted = ""
            let cleaned = input.replacingOccurrences(of: ">\s*<", with: "><", options: .regularExpression)
            for char in cleaned {
                if char == "<" {
                    let nextIdx = cleaned.index(cleaned.startIndex, offsetBy: formatted.count + 1, limitedBy: cleaned.endIndex)
                    if let ni = nextIdx, cleaned[ni] == "/" { indentLevel = max(0, indentLevel - 1) }
                    formatted += "\n" + String(repeating: "  ", count: indentLevel)
                }
                formatted += String(char)
                if char == ">" {
                    let prevIdx = cleaned.index(cleaned.startIndex, offsetBy: max(0, formatted.count - 2))
                    if cleaned[prevIdx] != "/" { indentLevel += 1 }
                }
            }
            output = formatted.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
