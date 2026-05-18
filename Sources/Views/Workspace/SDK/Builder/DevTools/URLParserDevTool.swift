import SwiftUI

struct URLParserTool: DevTool {
    let id = UUID()
    let name = "URL Parser"
    let category: DevToolCategory = .inputOutput
    let icon = "globe"
    let description = "Parse and inspect URL components"
    func render() -> some View { URLParserDevToolView() }
}

struct URLParserDevToolView: View {
    @State private var input = "https://example.com:8080/path?key=value&foo=bar#section"
    @State private var components: [(String, String)] = []
    var body: some View {
        Form {
            Section("URL") {
                TextField("Enter URL", text: $input)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Parse") { parseURL() }
                    .disabled(input.isEmpty)
            }
            if !components.isEmpty {
                Section("Components") {
                    ForEach(Array(components.enumerated()), id: \.offset) { _, pair in
                        LabeledContent(pair.0, value: pair.1)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle("URL Parser")
    }
    private func parseURL() {
        components.removeAll()
        guard let url = URL(string: input),
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            components = [("Error", "Invalid URL")]
            return
        }
        if let s = comps.scheme { components.append(("Scheme", s)) }
        if let h = comps.host { components.append(("Host", h)) }
        if let p = comps.port { components.append(("Port", "\(p)")) }
        if !comps.path.isEmpty { components.append(("Path", comps.path)) }
        if let q = comps.query { components.append(("Query", q)) }
        if let f = comps.fragment { components.append(("Fragment", f)) }
        if let items = comps.queryItems {
            for item in items {
                components.append(("Param: \(item.name)", item.value ?? "nil"))
            }
        }
    }
}
