import SwiftUI

struct JSONValidatorDevTool: DevTool {
    let id = "json-validator"
    let name = "JSON Validator"
    let category = DevToolCategory.data
    let icon = "checkmark.seal"
    let description = "Validate JSON syntax and structure"

    func render() -> some View {
        JSONValidatorView()
    }
}

struct JSONValidatorView: View {
    @StateObject private var viewModel = JSONValidatorViewModel()

    var body: some View {
        Form {
            Section("Input JSON") {
                TextEditor(text: $viewModel.input)
                    .frame(height: 200)
                    .font(.system(.caption, design: .monospaced))
            }

            Section("Status") {
                HStack {
                    Text(viewModel.isValid ? "Valid JSON" : "Invalid JSON")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(viewModel.isValid ? Color.green : Color.red, in: RoundedRectangle(cornerRadius: 4))
                    Spacer()
                    if !viewModel.isValid {
                        Text(viewModel.errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            if viewModel.isValid {
                Section("Metadata") {
                    LabeledContent("Type", value: viewModel.rootType)
                    LabeledContent("Key Count", value: "\(viewModel.keyCount)")
                }
            }
        }
    }
}

class JSONValidatorViewModel: ObservableObject {
    @Published var input = "{\n  \"status\": \"success\",\n  \"code\": 200\n}" {
        didSet { validate() }
    }
    @Published var isValid = true
    @Published var errorMessage = ""
    @Published var rootType = "Object"
    @Published var keyCount = 0

    private func validate() {
        guard !input.isEmpty else {
            isValid = true
            errorMessage = ""
            return
        }

        guard let data = input.data(using: .utf8) else {
            isValid = false
            errorMessage = "Unable to convert to UTF-8"
            return
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            isValid = true
            errorMessage = ""

            if let dict = json as? [String: Any] {
                rootType = "Object"
                keyCount = dict.keys.count
            } else if let array = json as? [Any] {
                rootType = "Array"
                keyCount = array.count
            }
        } catch {
            isValid = false
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    JSONValidatorView()
}
