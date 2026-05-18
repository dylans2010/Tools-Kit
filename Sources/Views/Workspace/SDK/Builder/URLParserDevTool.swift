import SwiftUI

struct URLParserDevTool: DevTool {
    let id = "url-parser"
    let name = "URL Parser"
    let category = DevToolCategory.inputOutput
    let icon = "magnifyingglass.circle"
    let description = "Parse URL components"

    func render() -> some View {
        URLParserView()
    }
}

struct URLParserView: View {
    @StateObject private var viewModel = URLParserViewModel()

    var body: some View {
        Form {
            Section("URL Input") {
                TextField("https://example.com/path?query=1", text: $viewModel.inputText)
                    .font(.monospaced(.body)())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            if let components = viewModel.components {
                Section("Components") {
                    LabeledContent("Scheme", value: components.scheme ?? "none")
                    LabeledContent("Host", value: components.host ?? "none")
                    LabeledContent("Port", value: components.port?.description ?? "none")
                    LabeledContent("Path", value: components.path)
                    LabeledContent("Query", value: components.query ?? "none")
                    LabeledContent("Fragment", value: components.fragment ?? "none")
                }

                if !viewModel.queryItems.isEmpty {
                    Section("Query Items") {
                        ForEach(viewModel.queryItems, id: \.name) { item in
                            LabeledContent(item.name, value: item.value ?? "nil")
                        }
                    }
                }
            } else if !viewModel.inputText.isEmpty {
                Section {
                    Text("Invalid URL")
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

class URLParserViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            components = URLComponents(string: inputText)
        }
    }
    @Published var components: URLComponents?

    var queryItems: [URLQueryItem] {
        components?.queryItems ?? []
    }
}
