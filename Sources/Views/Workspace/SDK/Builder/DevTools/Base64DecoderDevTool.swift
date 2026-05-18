import SwiftUI

struct Base64DecoderTool: DevTool {
    let id = UUID()
    let name = "Base64 Decoder"
    let category: DevToolCategory = .inputOutput
    let icon = "doc.text.below.ecg"
    let description = "Decode Base64 to text"
    func render() -> some View { Base64DecoderDevToolView() }
}

struct Base64DecoderDevToolView: View {
    @State private var input = ""
    @State private var output = ""
    @State private var errorMsg: String?
    var body: some View {
        Form {
            Section("Base64 Input") {
                TextEditor(text: $input)
                    .frame(minHeight: 100)
                    .font(.system(.body, design: .monospaced))
            }
            Section {
                Button("Decode") {
                    errorMsg = nil
                    guard let data = Data(base64Encoded: input.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                        errorMsg = "Invalid Base64 string"
                        return
                    }
                    output = String(data: data, encoding: .utf8) ?? "Unable to decode as UTF-8"
                }
                .disabled(input.isEmpty)
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            Section("Decoded Output") {
                if output.isEmpty {
                    Text("Decoded result will appear here").foregroundStyle(.secondary)
                } else {
                    Text(output).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Base64 Decoder")
    }
}
