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
        Form {
            Section(header: Text("Input URL")) {
                TextEditor(text: $viewModel.input)
                    .frame(height: 80)
                    .font(.system(.caption, design: .monospaced))
            }

            if !viewModel.components.isEmpty {
                Section(header: Text("Components")) {
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

            Section {
                HStack {
                    Text("History")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        viewModel.history.removeAll()
                    }
                    .font(.caption)
                    .disabled(viewModel.history.isEmpty)
                }

                if viewModel.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock", description: Text("Your activity will appear here."))
                        .frame(height: 200)
                } else {
                    List {
                        ForEach(viewModel.history) { item in
                            Button {
                                viewModel.input = item.title
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.subheadline.bold())
                                    Text(item.detail)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .foregroundStyle(.secondary)
                                    Text(item.timestamp, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 300)
                }
            } header: {
                Text("History")
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

#Preview {
    URLParserDevToolView()
}
