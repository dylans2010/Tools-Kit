import SwiftUI

struct JSONFormatterTool: DevTool {
    let id = UUID()
    let name = "JSON Formatter"
    let category: DevToolCategory = .data
    let icon = "curlybraces"
    let description = "Format and prettify JSON data"
    func render() -> some View { JSONFormatterDevToolView() }
}

struct JSONFormatterDevToolView: View {
    @State private var input = ""
    @State private var output = ""
    @State private var errorMsg: String?
    @State private var indentSize = 2
    var body: some View {
        Form {
            Section("Raw JSON") {
                TextEditor(text: $input).frame(minHeight: 120).font(.system(.body, design: .monospaced))
            }
            Section {
                Picker("Indent", selection: $indentSize) {
                    Text("2 spaces").tag(2)
                    Text("4 spaces").tag(4)
                    Text("Tab").tag(0)
                }
                Button("Format") { format() }
                    .disabled(input.isEmpty)
                Button("Minify") { minify() }
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
        .navigationTitle("JSON Formatter")
    }
    private func format() {
        errorMsg = nil
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            errorMsg = "Invalid JSON"
            return
        }
        guard let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) else { return }
        output = String(data: pretty, encoding: .utf8) ?? ""
    }
    private func minify() {
        errorMsg = nil
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            errorMsg = "Invalid JSON"
            return
        }
        guard let compact = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]) else { return }
        output = String(data: compact, encoding: .utf8) ?? ""
    }
}
