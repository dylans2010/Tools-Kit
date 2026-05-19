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
        List {
            Section("Raw URL Input") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 100)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    if !viewModel.input.isEmpty {
                        Button { viewModel.input = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }

                HStack {
                    Button("Paste") {
                        if let s = UIPasteboard.general.string { viewModel.input = s }
                    }
                    .buttonStyle(.bordered).controlSize(.small)

                    Spacer()

                    Button("Encode URL") { viewModel.encode() }
                        .font(.caption2)
                    Button("Decode URL") { viewModel.decode() }
                        .font(.caption2)
                }
            }

            if !viewModel.components.isEmpty {
                Section("Component Breakdown") {
                    ForEach(viewModel.components) { component in
                        HStack(alignment: .top) {
                            Text(component.key)
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(.blue)
                                .frame(width: 70, alignment: .leading)
                                .padding(.top, 2)

                            Text(component.value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)

                            Spacer()

                            Button { UIPasteboard.general.string = component.value } label: {
                                Image(systemName: "doc.on.doc").font(.system(size: 10))
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Query Parameters") {
                    if viewModel.queryParams.isEmpty {
                        Text("No query parameters found").font(.caption2).foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.queryParams, id: \.key) { param in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(param.key).font(.caption.bold())
                                Text(param.value).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Parsing History") {
                if viewModel.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock.arrow.circlepath", description: Text("Parsed URLs will be cached here."))
                } else {
                    ForEach(viewModel.history) { item in
                        Button {
                            viewModel.input = item.title
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.system(size: 10, design: .monospaced)).lineLimit(1)
                                Text(item.timestamp, style: .time).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete { viewModel.history.remove(atOffsets: $0) }
                }
            }
        }
        .navigationTitle("URL Lab")
    }
}

struct URLComponentItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

class URLParserViewModel: ObservableObject {
    @Published var input = "https://user:pass@example.com:8080/path/to/resource?q=test#fragment" {
        didSet { parse() }
    }
    @Published var components: [URLComponentItem] = []
    @Published var queryParams: [(key: String, value: String)] = []
    @Published var history: [HistoryItem] = []

    func encode() {
        if let encoded = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            input = encoded
        }
    }

    func decode() {
        if let decoded = input.removingPercentEncoding {
            input = decoded
        }
    }

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
