import SwiftUI

struct URLEncoderDevTool: DevTool {
    let id = "url-encoder"
    let name = "URL Encoder"
    let category = DevToolCategory.encoding
    let icon = "link"
    let description = "Percent-encode strings for use in URLs"

    func render() -> some View {
        URLEncoderView()
    }
}

struct URLEncoderView: View {
    @StateObject private var viewModel = URLEncoderViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "URL Encoder",
                description: "Encode special characters into percent-encoded sequences for valid URL formatting.",
                icon: "link"
            )
            .padding()

            Form {
                Section("Input") {
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 120)
                        .font(.system(.body, design: .monospaced))
                }

                Section("Output") {
                    Text(viewModel.outputText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(minHeight: 60)

                    ExportPanel(content: viewModel.outputText, filename: "url_encoded.txt")
                }

                Section("History") {
                    HistoryView(history: viewModel.history) { item in
                        viewModel.inputText = item.title
                    } onClear: {
                        viewModel.history.removeAll()
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}

class URLEncoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            encode()
        }
    }
    @Published var outputText = ""
    @Published var history: [HistoryItem] = []

    private func encode() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }

        outputText = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if history.first?.title != inputText {
            history.insert(HistoryItem(title: inputText, detail: "URL Encoded"), at: 0)
        }
    }
}
