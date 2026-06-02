import SwiftUI

struct CURLGeneratorDevTool: DevTool {
    let id = "curl-generator"
    let name = "cURL Generator"
    let category: DevToolCategory = .networking
    let icon = "chevron.left.forwardslash.chevron.right"
    let description = "Generate cURL commands from structured input"

    func render() -> some View {
        CURLGeneratorView()
    }
}

struct CURLGeneratorView: View {
    @State private var url = "https://api.example.com"
    @State private var method = "GET"
    @State private var body = ""
    @State private var headers = "Content-Type: application/json"
    @State private var result = ""

    var body: some View {
        Form {
            Section("Details") {
                TextField("URL", text: $url)
                Picker("Method", selection: $method) {
                    ForEach(["GET", "POST", "PUT", "DELETE"], id: \.self) { Text($0) }
                }.pickerStyle(.segmented)
            }
            Section("Headers (One per line)") {
                TextEditor(text: $headers)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 80)
            }
            Section("Body") {
                TextEditor(text: $body)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 100)
            }
            Button("Generate cURL") {
                generate()
            }
            .frame(maxWidth: .infinity)

            if !result.isEmpty {
                Section("Result") {
                    Text(result)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func generate() {
        var cmd = "curl -X \(method) \"\(url)\""
        let lines = headers.components(separatedBy: "\n").filter { !$0.isEmpty }
        for line in lines { cmd += " -H \"\(line)\"" }
        if !body.isEmpty && method != "GET" {
            cmd += " -d '\(body)'"
        }
        result = cmd
    }
}
