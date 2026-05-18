import SwiftUI

struct URLEncoderTool: DevTool {
    let id = UUID()
    let name = "URL Encoder"
    let category: DevToolCategory = .inputOutput
    let icon = "link"
    let description = "Percent-encode strings for URLs"
    func render() -> some View { URLEncoderDevToolView() }
}

struct URLEncoderDevToolView: View {
    @State private var input = ""
    @State private var output = ""
    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $input).frame(minHeight: 80).font(.system(.body, design: .monospaced))
            }
            Section {
                Button("Encode") {
                    output = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
                }
                .disabled(input.isEmpty)
            }
            Section("Encoded Output") {
                if output.isEmpty {
                    Text("Result will appear here").foregroundStyle(.secondary)
                } else {
                    Text(output).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("URL Encoder")
    }
}
