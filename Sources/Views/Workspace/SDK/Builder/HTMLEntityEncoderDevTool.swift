import SwiftUI

struct HTMLEntityEncoderDevTool: DevTool {
    let id = "html-entity-encoder"
    let name = "HTML Entity Encoder"
    let category = DevToolCategory.encoding
    let icon = "chevron.left.forwardslash.chevron.right"
    let description = "Encode characters to HTML entities"

    func render() -> some View {
        HTMLEntityEncoderView()
    }
}

struct HTMLEntityEncoderView: View {
    @StateObject private var viewModel = HTMLEntityEncoderViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "HTML Entity Encoder",
                description: "Escape special characters into HTML entities for safe inclusion in web content.",
                icon: "chevron.left.forwardslash.chevron.right"
            )
            .padding()

            Form {
                Section("Plain Text") {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 120)
                }

                Section("HTML Entities") {
                    Text(viewModel.output)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(minHeight: 60)

                    ExportPanel(content: viewModel.output, filename: "html_encoded.txt")
                }

                Section("Options") {
                    Toggle("Encode All Non-ASCII", isOn: $viewModel.encodeNonASCII)
                }
            }
        }
    }
}

class HTMLEntityEncoderViewModel: ObservableObject {
    @Published var input = "<b>Hello & World</b>" {
        didSet { encode() }
    }
    @Published var output = ""
    @Published var encodeNonASCII = false {
        didSet { encode() }
    }

    private func encode() {
        var result = ""
        for scalar in input.unicodeScalars {
            switch scalar.value {
            case 38: result += "&amp;"
            case 60: result += "&lt;"
            case 62: result += "&gt;"
            case 34: result += "&quot;"
            case 39: result += "&apos;"
            case let v where v > 127 && encodeNonASCII:
                result += "&#\(v);"
            default:
                result += String(scalar)
            }
        }
        output = result
    }
}
