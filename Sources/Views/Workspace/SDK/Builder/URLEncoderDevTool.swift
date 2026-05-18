import SwiftUI

struct URLEncoderDevTool: DevTool {
    let id = "url-encoder"
    let name = "URL Encoder"
    let category = DevToolCategory.inputOutput
    let icon = "link.badge.plus"
    let description = "Percent-encode text for URLs"

    func render() -> some View {
        URLEncoderView()
    }
}

struct URLEncoderView: View {
    @StateObject private var viewModel = URLEncoderViewModel()

    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
                    .font(.monospaced(.body)())
            }

            Section("Encoded Output") {
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

class URLEncoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            outputText = URLEncoderService.encode(inputText)
        }
    }
    @Published var outputText = ""
}

struct URLEncoderService {
    static func encode(_ text: String) -> String {
        return text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
}
