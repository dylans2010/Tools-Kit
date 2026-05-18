import SwiftUI

struct QueryStringParserDevTool: DevTool {
    let id = "query-string-parser"
    let name = "Query String Parser"
    let category = DevToolCategory.inputOutput
    let icon = "questionmark.square"
    let description = "Parse URL query parameters"

    func render() -> some View {
        QueryStringParserView()
    }
}

struct QueryStringParserView: View {
    @StateObject private var viewModel = QueryStringParserViewModel()

    var body: some View {
        Form {
            Section("Query String") {
                TextField("key1=value1&key2=value2", text: $viewModel.inputText)
                    .font(.monospaced(.body)())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Section("Parsed Parameters") {
                if viewModel.parameters.isEmpty {
                    Text("No parameters found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.parameters, id: \.key) { param in
                        LabeledContent(param.key, value: param.value)
                    }
                }
            }
        }
    }
}

class QueryStringParserViewModel: ObservableObject {
    @Published var inputText = ""

    var parameters: [(key: String, value: String)] {
        let items = inputText.components(separatedBy: "&")
        return items.compactMap { item in
            let parts = item.components(separatedBy: "=")
            guard parts.count == 2 else { return nil }
            return (key: parts[0], value: parts[1].removingPercentEncoding ?? parts[1])
        }
    }
}
