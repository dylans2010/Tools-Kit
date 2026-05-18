import SwiftUI

struct URLDecoderTool: DevTool {
    let id = UUID()
    let name = "URL Decoder"
    let category: DevToolCategory = .inputOutput
    let icon = "link.badge.plus"
    let description = "Decode percent-encoded URLs"
    func render() -> some View { URLDecoderDevToolView() }
}

struct URLDecoderDevToolView: View {
    @State private var input = ""
    @State private var output = ""
    var body: some View {
        Form {
            Section("Encoded Input") {
                TextEditor(text: $input).frame(minHeight: 80).font(.system(.body, design: .monospaced))
            }
            Section {
                Button("Decode") {
                    output = input.removingPercentEncoding ?? input
                }
                .disabled(input.isEmpty)
            }
            Section("Decoded Output") {
                if output.isEmpty {
                    Text("Result will appear here").foregroundStyle(.secondary)
                } else {
                    Text(output).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("URL Decoder")
    }
}
