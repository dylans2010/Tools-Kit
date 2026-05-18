import SwiftUI

struct Base64EncoderDevTool: DevTool {
    let id = "base64-encoder"
    let name = "Base64 Encoder"
    let category = DevToolCategory.inputOutput
    let icon = "text.and.command.macwindow"
    let description = "Encode text to Base64"

    func render() -> some View {
        Base64EncoderView()
    }
}

struct Base64EncoderView: View {
    @StateObject private var viewModel = Base64EncoderViewModel()

    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
                    .font(.monospaced(.body)())
            }

            Section("Output") {
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

class Base64EncoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            outputText = Base64EncoderService.encode(inputText)
        }
    }
    @Published var outputText = ""
}

struct Base64EncoderService {
    static func encode(_ text: String) -> String {
        guard let data = text.data(using: .utf8) else { return "" }
        return data.base64EncodedString()
    }
}
