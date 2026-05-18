import SwiftUI

struct URLDecoderDevTool: DevTool {
    let id = "url-decoder"
    let name = "URL Decoder"
    let category = DevToolCategory.inputOutput
    let icon = "link.badge.minus"
    let description = "Decode percent-encoded URL text"

    func render() -> some View {
        URLDecoderView()
    }
}

struct URLDecoderView: View {
    @StateObject private var viewModel = URLDecoderViewModel()

    var body: some View {
        Form {
            Section("Encoded Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
                    .font(.monospaced(.body)())
            }

            Section("Decoded Output") {
                Text(viewModel.outputText)
                    .font(.monospaced(.body)())
                    .textSelection(.enabled)

                Button {
                    UIPasteboard.general.string = viewModel.outputText
                } label: {
                    Label("Copy to Clipboard", systemImage: "doc.on.doc")
                }
                .disabled(viewModel.outputText.isEmpty)
            }
        }
    }
}

class URLDecoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            outputText = URLDecoderService.decode(inputText)
        }
    }
    @Published var outputText = ""
}

struct URLDecoderService {
    static func decode(_ text: String) -> String {
        return text.removingPercentEncoding ?? ""
    }
}
