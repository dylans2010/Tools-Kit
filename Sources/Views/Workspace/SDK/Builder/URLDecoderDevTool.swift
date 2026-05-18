import SwiftUI

struct URLDecoderDevTool: DevTool {
    let id = "url-decoder"
    let name = "URL Decoder"
    let category = DevToolCategory.encoding
    let icon = "link.badge.plus"
    let description = "Decode percent-encoded URL strings"

    func render() -> some View {
        URLDecoderView()
    }
}

struct URLDecoderView: View {
    @StateObject private var viewModel = URLDecoderViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "URL Decoder",
                description: "Reverse percent-encoding in URLs to retrieve original readable strings.",
                icon: "link.badge.plus"
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

                    ExportPanel(content: viewModel.outputText, filename: "url_decoded.txt")
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

class URLDecoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            decode()
        }
    }
    @Published var outputText = ""
    @Published var history: [HistoryItem] = []

    private func decode() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }

        outputText = inputText.removingPercentEncoding ?? ""

        if history.first?.title != inputText {
            history.insert(HistoryItem(title: inputText, detail: "URL Decoded"), at: 0)
        }
    }
}
