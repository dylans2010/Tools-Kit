import SwiftUI

struct HTMLEntityEncoderTool: DevTool {
    let id = UUID()
    let name = "HTML Entity Encoder"
    let category: DevToolCategory = .inputOutput
    let icon = "chevron.left.forwardslash.chevron.right"
    let description = "Encode special characters as HTML entities"
    func render() -> some View { HTMLEntityEncoderDevToolView() }
}

struct HTMLEntityEncoderDevToolView: View {
    @State private var input = ""
    @State private var output = ""
    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $input).frame(minHeight: 80).font(.system(.body, design: .monospaced))
            }
            Section {
                Button("Encode") {
                    output = input
                        .replacingOccurrences(of: "&", with: "&amp;")
                        .replacingOccurrences(of: "<", with: "&lt;")
                        .replacingOccurrences(of: ">", with: "&gt;")
                        .replacingOccurrences(of: "\"", with: "&quot;")
                        .replacingOccurrences(of: "'", with: "&#39;")
                }
                .disabled(input.isEmpty)
            }
            Section("Encoded") {
                if output.isEmpty {
                    Text("Result will appear here").foregroundStyle(.secondary)
                } else {
                    Text(output).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("HTML Entity Encoder")
    }
}
