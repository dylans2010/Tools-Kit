import SwiftUI

struct Base64EncoderDevTool: DevTool {
    let id = "base64-encoder"
    let name = "Base64 Encoder"
    let category = DevToolCategory.encoding
    let icon = "text.and.command.macwindow"
    let description = "Encode text or binary data to Base64"

    func render() -> some View {
        Base64EncoderView()
    }
}

struct Base64EncoderView: View {
    @StateObject private var viewModel = Base64EncoderViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Base64 Encoder",
                description: "Convert strings to Base64 with support for URL-safe encoding and different character sets.",
                icon: "text.and.command.macwindow"
            )
            .padding()

            Form {
                Section("Input") {
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 120)
                        .font(.system(.body, design: .monospaced))
                }

                Section("Configuration") {
                    Toggle("URL Safe Encoding", isOn: $viewModel.isURLSafe)
                    Picker("Encoding", selection: $viewModel.encoding) {
                        Text("UTF-8").tag(String.Encoding.utf8)
                        Text("UTF-16").tag(String.Encoding.utf16)
                        Text("ASCII").tag(String.Encoding.ascii)
                    }
                }

                Section("Output") {
                    Text(viewModel.outputText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(minHeight: 60)

                    ExportPanel(content: viewModel.outputText, filename: "encoded_base64.txt")
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

class Base64EncoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            encode()
        }
    }
    @Published var outputText = ""
    @Published var isURLSafe = false {
        didSet { encode() }
    }
    @Published var encoding = String.Encoding.utf8 {
        didSet { encode() }
    }
    @Published var history: [HistoryItem] = []

    private func encode() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }

        guard let data = inputText.data(using: encoding) else {
            outputText = "Invalid encoding"
            return
        }

        var base64 = data.base64EncodedString()
        if isURLSafe {
            base64 = base64.replacingOccurrences(of: "+", with: "-")
                           .replacingOccurrences(of: "/", with: "_")
                           .replacingOccurrences(of: "=", with: "")
        }

        outputText = base64

        // Update history periodically or on specific triggers to avoid spam
        if history.first?.title != inputText {
             history.insert(HistoryItem(title: inputText, detail: "Encoded to \(encoding)"), at: 0)
        }
    }
}
