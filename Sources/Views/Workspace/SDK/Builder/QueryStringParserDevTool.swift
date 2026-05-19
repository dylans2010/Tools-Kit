import SwiftUI

struct QueryStringParserDevTool: DevTool {
    let id = "query-string-parser"
    let name = "Query String Parser"
    let category = DevToolCategory.inputOutput
    let icon = "text.badge.plus"
    let description = "Parse and edit URL query parameters"

    func render() -> some View {
        QueryStringParserView()
    }
}

struct QueryStringParserView: View {
    @StateObject private var viewModel = QueryStringParserViewModel()

    var body: some View {
        List {
            Section("Source") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 100)
                        .font(.system(.caption, design: .monospaced))
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    Button { viewModel.input = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .padding(8)
                }
            }

            Section {
                if viewModel.parameters.isEmpty {
                    ContentUnavailableView("No Parameters", systemImage: "text.badge.minus", description: Text("No key-value pairs detected."))
                } else {
                    ForEach($viewModel.parameters) { $param in
                        HStack(spacing: 12) {
                            TextField("Key", text: $param.key)
                                .font(.caption.bold())
                                .frame(width: 100)

                            Divider()

                            TextField("Value", text: $param.value)
                                .font(.system(size: 11, design: .monospaced))
                        }
                    }
                    .onDelete { viewModel.parameters.remove(atOffsets: $0) }
                }

                Button {
                    viewModel.parameters.append(QueryParameter(key: "new_key", value: ""))
                } label: {
                    Label("Add Pair", systemImage: "plus.circle")
                }
            } header: {
                HStack {
                    Text("Parameters")
                    Spacer()
                    if !viewModel.parameters.isEmpty {
                        Text("\(viewModel.parameters.count)").font(.caption2)
                    }
                }
            }

            Section("Generated String") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.output)
                        .font(.system(.caption2, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(6)
                        .textSelection(.enabled)

                    HStack {
                        Button {
                            UIPasteboard.general.string = viewModel.output
                        } label: {
                            Label("Copy Result", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderedProminent)

                        Spacer()

                        Button("URL Decode Keys") {
                            viewModel.decodeAll()
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Query Parser")
    }
}

struct QueryParameter: Identifiable {
    let id = UUID()
    var key: String
    var value: String
}

class QueryStringParserViewModel: ObservableObject {
    @Published var input = "https://api.example.com/v1/search?q=toolskit+sdk&limit=25&offset=0&active=true" {
        didSet {
            if input != oldValue { parse() }
        }
    }
    @Published var parameters: [QueryParameter] = []

    var output: String {
        guard !parameters.isEmpty else { return "" }
        let pairs = parameters.map {
            let k = $0.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.key
            let v = $0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value
            return "\(k)=\(v)"
        }
        return "?" + pairs.joined(separator: "&")
    }

    init() { parse() }

    func decodeAll() {
        parameters = parameters.map {
            QueryParameter(
                key: $0.key.removingPercentEncoding ?? $0.key,
                value: $0.value.removingPercentEncoding ?? $0.value
            )
        }
    }

    private func parse() {
        guard let url = URL(string: input),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            let raw = input.hasPrefix("?") ? String(input.dropFirst()) : input
            let pairs = raw.components(separatedBy: "&")
            parameters = pairs.compactMap { pair -> QueryParameter? in
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return nil }
                return QueryParameter(key: parts[0], value: parts[1])
            }
            return
        }

        parameters = queryItems.map { QueryParameter(key: $0.name, value: $0.value ?? "") }
    }
}

#Preview {
    QueryStringParserView()
}
