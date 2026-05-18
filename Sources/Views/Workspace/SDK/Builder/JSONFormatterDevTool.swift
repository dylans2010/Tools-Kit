import SwiftUI

struct JSONFormatterDevTool: DevTool {
    let id = "json-formatter"
    let name = "JSON Formatter"
    let category = DevToolCategory.data
    let icon = "curlybraces"
    let description = "Prettify and format JSON strings"

    func render() -> some View {
        JSONFormatterView()
    }
}

struct JSONFormatterView: View {
    @StateObject private var viewModel = JSONFormatterViewModel()

    var body: some View {
        Form {
            Section("JSON Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 150)
                    .font(.monospaced(.body)())
            }

            Section("Formatted Output") {
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

class JSONFormatterViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            format()
        }
    }
    @Published var outputText = ""
    @Published var errorMessage: String?

    private func format() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            outputText = ""
            errorMessage = nil
            return
        }

        guard let data = inputText.data(using: .utf8) else {
            errorMessage = "Invalid encoding"
            return
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            outputText = String(data: prettyData, encoding: .utf8) ?? ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
