import SwiftUI

struct URLParserDevTool: DevTool {
    let id = "url-parser"
    let name = "URL Parser"
    let category = DevToolCategory.encoding
    let icon = "link.circle"
    let description = "Break down URLs into components"

    func render() -> some View {
        URLParserDevToolView()
    }
}

struct URLParserDevToolView: View {
    @StateObject private var viewModel = URLParserViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "URL Parser",
                description: "Inspect and modify individual components of a URL such as scheme, host, path, and query.",
                icon: "link.circle"
            )
            .padding()

            Form {
                Section("Input URL") {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 80)
                        .font(.system(.caption, design: .monospaced))
                }

                if !viewModel.components.isEmpty {
                    Section("Components") {
                        ForEach(viewModel.components) { component in
                            HStack {
                                Text(component.key)
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.accentColor)
                                Spacer()
                                Text(component.value)
                                    .font(.caption)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }

                Section("History") {
                    HistoryView(history: viewModel.history) { item in
                        viewModel.input = item.title
                    } onClear: {
                        viewModel.history.removeAll()
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}

struct URLComponentItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

class URLParserViewModel: ObservableObject {
    @Published var input = "https://user:pass@example.com:8080/path/to/resource?q=test#fragment" {
        didSet {
            parse()
        }
    }
    @Published var components: [URLComponentItem] = []
    @Published var history: [HistoryItem] = []

    private func parse() {
        guard let url = URL(string: input),
              let comp = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            components = []
            return
        }

        var items: [URLComponentItem] = []
        if let s = comp.scheme { items.append(URLComponentItem(key: "Scheme", value: s)) }
        if let u = comp.user { items.append(URLComponentItem(key: "User", value: u)) }
        if let p = comp.password { items.append(URLComponentItem(key: "Password", value: p)) }
        if let h = comp.host { items.append(URLComponentItem(key: "Host", value: h)) }
        if let port = comp.port { items.append(URLComponentItem(key: "Port", value: "\(port)")) }
        if !comp.path.isEmpty { items.append(URLComponentItem(key: "Path", value: comp.path)) }
        if let q = comp.query { items.append(URLComponentItem(key: "Query", value: q)) }
        if let f = comp.fragment { items.append(URLComponentItem(key: "Fragment", value: f)) }

        components = items

        if history.first?.title != input {
            history.insert(HistoryItem(title: input, detail: "Parsed into \(items.count) components"), at: 0)
        }
    }
}
