import SwiftUI

struct APIResponseViewerDevTool: DevTool {
    let id = "api-response-viewer"
    let name = "API Response Viewer"
    let category = DevToolCategory.networking
    let icon = "doc.plaintext"
    let description = "View and format API responses"

    func render() -> some View {
        APIResponseViewerView()
    }
}

struct APIResponseViewerView: View {
    @StateObject private var viewModel = APIResponseViewerViewModel()

    var body: some View {
        VStack {
            Form {
                Section("Input Response") {
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 100)
                        .font(.monospaced(.body)())
                }
            }
            .frame(height: 180)

            List {
                Section("Formatted Viewer") {
                    Text(viewModel.formattedText)
                        .font(.monospaced(.caption)())
                        .textSelection(.enabled)
                }
            }
        }
    }
}

class APIResponseViewerViewModel: ObservableObject {
    @Published var inputText = "{\"message\": \"Hello World\"}"

    var formattedText: String {
        guard let data = inputText.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            return inputText
        }
        return String(data: prettyData, encoding: .utf8) ?? inputText
    }
}
