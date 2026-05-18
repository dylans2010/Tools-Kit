import SwiftUI

struct HTMLEntityDecoderDevTool: DevTool {
    let id = "html-entity-decoder"
    let name = "HTML Entity Decoder"
    let category = DevToolCategory.inputOutput
    let icon = "chevron.left.chevron.right"
    let description = "Decode HTML entities to text"

    func render() -> some View {
        HTMLEntityDecoderView()
    }
}

struct HTMLEntityDecoderView: View {
    @StateObject private var viewModel = HTMLEntityDecoderViewModel()

    var body: some View {
        Form {
            Section("Encoded Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
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

class HTMLEntityDecoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            outputText = HTMLEntityService.decode(inputText)
        }
    }
    @Published var outputText = ""
}
