import SwiftUI

struct Base64DecoderDevTool: DevTool {
    let id = "base64-decoder"
    let name = "Base64 Decoder"
    let category = DevToolCategory.inputOutput
    let icon = "text.badge.checkmark"
    let description = "Decode Base64 to text"

    func render() -> some View {
        Base64DecoderView()
    }
}

struct Base64DecoderView: View {
    @StateObject private var viewModel = Base64DecoderViewModel()

    var body: some View {
        Form {
            Section("Base64 Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
                    .font(.monospaced(.body)())
            }

            Section("Decoded Output") {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                } else {
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
}

class Base64DecoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            let result = Base64DecoderService.decode(inputText)
            outputText = result.text
            errorMessage = result.error
        }
    }
    @Published var outputText = ""
    @Published var errorMessage: String?
}

struct Base64DecoderService {
    static func decode(_ base64: String) -> (text: String, error: String?) {
        guard !base64.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return ("", nil) }
        guard let data = Data(base64Encoded: base64.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return ("", "Invalid Base64 string")
        }
        if let decoded = String(data: data, encoding: .utf8) {
            return (decoded, nil)
        } else {
            return ("", "Decoded data is not valid UTF-8 text")
        }
    }
}
