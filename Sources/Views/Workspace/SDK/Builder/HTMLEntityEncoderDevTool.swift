import SwiftUI

struct HTMLEntityEncoderDevTool: DevTool {
    let id = "html-entity-encoder"
    let name = "HTML Entity Encoder"
    let category = DevToolCategory.inputOutput
    let icon = "chevron.left.forwardslash.chevron.right"
    let description = "Encode text to HTML entities"

    func render() -> some View {
        HTMLEntityEncoderView()
    }
}

struct HTMLEntityEncoderView: View {
    @StateObject private var viewModel = HTMLEntityEncoderViewModel()

    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
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

class HTMLEntityEncoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            outputText = HTMLEntityService.encode(inputText)
        }
    }
    @Published var outputText = ""
}

struct HTMLEntityService {
    static func encode(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            if scalar.value > 127 || "<>&\"'".contains(Character(scalar)) {
                result.append("&#\(scalar.value);")
            } else {
                result.append(Character(scalar))
            }
        }
        return result
    }

    static func decode(_ text: String) -> String {
        var result = text
        let mapping = [
            "&quot;": "\"",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&apos;": "'"
        ]
        for (entity, char) in mapping {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }
}
