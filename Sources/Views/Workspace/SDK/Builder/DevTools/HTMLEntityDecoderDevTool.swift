import SwiftUI

struct HTMLEntityDecoderTool: DevTool {
    let id = UUID()
    let name = "HTML Entity Decoder"
    let category: DevToolCategory = .inputOutput
    let icon = "doc.richtext"
    let description = "Decode HTML entities to text"
    func render() -> some View { HTMLEntityDecoderDevToolView() }
}

struct HTMLEntityDecoderDevToolView: View {
    @State private var input = ""
    @State private var output = ""
    var body: some View {
        Form {
            Section("Encoded Input") {
                TextEditor(text: $input).frame(minHeight: 80).font(.system(.body, design: .monospaced))
            }
            Section {
                Button("Decode") {
                    output = input
                        .replacingOccurrences(of: "&amp;", with: "&")
                        .replacingOccurrences(of: "&lt;", with: "<")
                        .replacingOccurrences(of: "&gt;", with: ">")
                        .replacingOccurrences(of: "&quot;", with: "\"")
                        .replacingOccurrences(of: "&#39;", with: "'")
                        .replacingOccurrences(of: "&nbsp;", with: " ")
                }
                .disabled(input.isEmpty)
            }
            Section("Decoded") {
                if output.isEmpty {
                    Text("Result will appear here").foregroundStyle(.secondary)
                } else {
                    Text(output).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("HTML Entity Decoder")
    }
}
