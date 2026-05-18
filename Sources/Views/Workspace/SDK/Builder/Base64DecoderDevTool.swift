import SwiftUI

struct Base64DecoderDevTool: DevTool {
    let id = "base64-decoder"
    let name = "Base64 Decoder"
    let category = DevToolCategory.encoding
    let icon = "command.square"
    let description = "Decode Base64 strings back to original format"

    func render() -> some View {
        Base64DecoderView()
    }
}

struct Base64DecoderView: View {
    @StateObject private var viewModel = Base64DecoderViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Base64 Decoder",
                description: "Decode Base64 strings including URL-safe variants and handle corrupted padding.",
                icon: "command.square"
            )
            .padding()

            Form {
                Section("Input Base64") {
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 120)
                        .font(.system(.body, design: .monospaced))
                }

                Section("Output") {
                    if viewModel.isError {
                        Text(viewModel.outputText)
                            .foregroundStyle(.red)
                            .font(.caption)
                    } else {
                        Text(viewModel.outputText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(minHeight: 60)
                    }

                    ExportPanel(content: viewModel.outputText, filename: "decoded_base64.txt")
                        .disabled(viewModel.isError)
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

class Base64DecoderViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            decode()
        }
    }
    @Published var outputText = ""
    @Published var isError = false
    @Published var history: [HistoryItem] = []

    private func decode() {
        guard !inputText.isEmpty else {
            outputText = ""
            isError = false
            return
        }

        var base64 = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        base64 = base64.replacingOccurrences(of: "-", with: "+")
                       .replacingOccurrences(of: "_", with: "/")

        // Fix padding
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 = base64.padding(toLength: base64.count + (4 - remainder), withPad: "=", startingAt: 0)
        }

        guard let data = Data(base64Encoded: base64) else {
            outputText = "Invalid Base64 format"
            isError = true
            return
        }

        if let decodedString = String(data: data, encoding: .utf8) {
            outputText = decodedString
            isError = false
        } else {
            outputText = "Data decoded but contains non-UTF8 characters (\(data.count) bytes)"
            isError = false
        }

        if history.first?.title != inputText {
            history.insert(HistoryItem(title: inputText, detail: isError ? "Failed decode" : "Decoded successfully"), at: 0)
        }
    }
}
