import SwiftUI

struct JSONValidatorDevTool: DevTool {
    let id = "json-validator"
    let name = "JSON Validator"
    let category = DevToolCategory.data
    let icon = "checkmark.seal"
    let description = "Validate JSON syntax"

    func render() -> some View {
        JSONValidatorView()
    }
}

struct JSONValidatorView: View {
    @StateObject private var viewModel = JSONValidatorViewModel()

    var body: some View {
        Form {
            Section("JSON Input") {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 200)
                    .font(.monospaced(.body)())
            }

            Section("Validation Result") {
                if viewModel.inputText.isEmpty {
                    Text("Enter JSON to validate")
                        .foregroundStyle(.secondary)
                } else if viewModel.isValid {
                    Label("Valid JSON", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    VStack(alignment: .leading) {
                        Label("Invalid JSON", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption.monospaced())
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }
}

class JSONValidatorViewModel: ObservableObject {
    @Published var inputText = "" {
        didSet {
            validate()
        }
    }
    @Published var isValid = false
    @Published var errorMessage: String?

    private func validate() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isValid = false
            errorMessage = nil
            return
        }

        guard let data = inputText.data(using: .utf8) else {
            isValid = false
            errorMessage = "Invalid encoding"
            return
        }

        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            isValid = true
            errorMessage = nil
        } catch {
            isValid = false
            errorMessage = error.localizedDescription
        }
    }
}
