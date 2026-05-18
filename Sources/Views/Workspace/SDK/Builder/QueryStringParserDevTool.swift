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
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Query String Parser",
                description: "Deconstruct URL query strings into editable key-value pairs.",
                icon: "text.badge.plus"
            )
            .padding()

            Form {
                Section("Input URL / Query String") {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 100)
                        .font(.system(.caption, design: .monospaced))
                }

                Section("Parameters") {
                    if viewModel.parameters.isEmpty {
                        Text("No parameters detected").foregroundStyle(.secondary)
                    } else {
                        ForEach($viewModel.parameters) { $param in
                            HStack {
                                TextField("Key", text: $param.key)
                                    .font(.caption.bold())
                                Divider()
                                TextField("Value", text: $param.value)
                                    .font(.caption)
                            }
                        }
                        .onDelete { viewModel.parameters.remove(atOffsets: $0) }
                    }

                    Button("Add Parameter") {
                        viewModel.parameters.append(QueryParameter(key: "key", value: "value"))
                    }
                }

                Section("Generated Output") {
                    Text(viewModel.output)
                        .font(.system(.caption2, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(4)
                        .textSelection(.enabled)

                    ExportPanel(content: viewModel.output, filename: "query_string.txt")
                }
            }
        }
    }
}

struct QueryParameter: Identifiable {
    let id = UUID()
    var key: String
    var value: String
}

class QueryStringParserViewModel: ObservableObject {
    @Published var input = "https://example.com/search?q=swiftui&category=dev&sort=newest" {
        didSet {
            parse()
        }
    }
    @Published var parameters: [QueryParameter] = []

    var output: String {
        guard !parameters.isEmpty else { return "" }
        let pairs = parameters.map { "\($0.key)=\($0.value)" }
        return "?" + pairs.joined(separator: "&")
    }

    private func parse() {
        guard let url = URL(string: input),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            // Try parsing as raw query string if URL parsing fails
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
