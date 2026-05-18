import SwiftUI

struct Base64EncoderTool: DevTool {
    let id = UUID()
    let name = "Base64 Encoder"
    let category: DevToolCategory = .inputOutput
    let icon = "doc.text"
    let description = "Encode text to Base64"
    func render() -> some View { Base64EncoderDevToolView() }
}

struct Base64EncoderDevToolView: View {
    @State private var input = ""
    @State private var output = ""
    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $input)
                    .frame(minHeight: 100)
                    .font(.system(.body, design: .monospaced))
            }
            Section {
                Button("Encode") {
                    if let data = input.data(using: .utf8) {
                        output = data.base64EncodedString()
                    }
                }
                .disabled(input.isEmpty)
            }
            Section("Output") {
                if output.isEmpty {
                    Text("Encoded result will appear here").foregroundStyle(.secondary)
                } else {
                    Text(output).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Base64 Encoder")
    }
}
