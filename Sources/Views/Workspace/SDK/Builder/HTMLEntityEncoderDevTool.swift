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
        Form {
            Section(header: Text("Plain Text")) {
                TextEditor(text: $viewModel.input)
                    .frame(height: 120)
            }

            Section(header: Text("HTML Entities")) {
                Text(viewModel.output)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(minHeight: 60)

                HStack {
                    Button {
                        UIPasteboard.general.string = viewModel.output
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("html_encoded.txt")
                        try? viewModel.output.write(to: fileURL, atomically: true, encoding: .utf8)
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section(header: Text("Options")) {
                Toggle("Encode All Non-ASCII", isOn: $viewModel.encodeNonASCII)
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

#Preview {
    HTMLEntityEncoderView()
}
