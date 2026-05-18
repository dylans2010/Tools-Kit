import SwiftUI

struct QueryStringParserTool: DevTool {
    let id = UUID()
    let name = "Query String Parser"
    let category: DevToolCategory = .inputOutput
    let icon = "questionmark.circle"
    let description = "Parse URL query strings into key-value pairs"
    func render() -> some View { QueryStringParserDevToolView() }
}

struct QueryStringParserDevToolView: View {
    @State private var input = "name=John&age=30&city=New+York&debug=true"
    @State private var pairs: [(String, String)] = []
    var body: some View {
        Form {
            Section("Query String") {
                TextField("key=value&key2=value2", text: $input)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Parse") { parse() }
                    .disabled(input.isEmpty)
            }
            if !pairs.isEmpty {
                Section("Parsed Parameters (\(pairs.count))") {
                    ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                        LabeledContent {
                            Text(pair.1).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                        } label: {
                            Text(pair.0).font(.system(.caption, design: .monospaced)).foregroundStyle(.accent)
                        }
                    }
                }
            }
        }
        .navigationTitle("Query String Parser")
    }
    private func parse() {
        let cleaned = input.hasPrefix("?") ? String(input.dropFirst()) : input
        let items = cleaned.split(separator: "&")
        pairs = items.map { item in
            let parts = item.split(separator: "=", maxSplits: 1)
            let key = (String(parts.first ?? "").removingPercentEncoding ?? String(parts.first ?? "")).replacingOccurrences(of: "+", with: " ")
            let value = parts.count > 1 ? ((String(parts[1]).removingPercentEncoding ?? String(parts[1])).replacingOccurrences(of: "+", with: " ")) : ""
            return (key, value)
        }
    }
}
