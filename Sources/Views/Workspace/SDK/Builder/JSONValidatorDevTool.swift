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
        List {
            Section("Syntax Source") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 200)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    if !viewModel.input.isEmpty {
                        Button { viewModel.input = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }

                HStack {
                    Button("Format") { viewModel.format() }
                        .buttonStyle(.bordered).controlSize(.small)
                    Spacer()
                    Button("Minify") { viewModel.minify() }
                        .buttonStyle(.bordered).controlSize(.small)
                }
            }

            Section("Validation Audit") {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isValid ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.title)
                        .foregroundStyle(viewModel.isValid ? .green : .red)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.isValid ? "Pass" : "Fail")
                            .font(.headline)
                        Text(viewModel.isValid ? "Syntax is structurally sound." : viewModel.errorMessage)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if viewModel.isValid && !viewModel.input.isEmpty {
                Section("Structural Insights") {
                    LabeledContent("Root Container", value: viewModel.rootType)
                    LabeledContent("Direct Children", value: "\(viewModel.keyCount)")
                    LabeledContent("Byte Size", value: "\(viewModel.input.utf8.count) B")
                }

                Section {
                    Button("Generate Swift Model") { viewModel.generateModel() }
                    Button("Copy Formatted JSON") { UIPasteboard.general.string = viewModel.input }
                }
            }
        }
        .navigationTitle("JSON Lab")
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

    func format() {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else { return }
        input = String(data: pretty, encoding: .utf8) ?? input
    }

    func minify() {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let minified = try? JSONSerialization.data(withJSONObject: json, options: []) else { return }
        input = String(data: minified, encoding: .utf8) ?? input
    }

    func generateModel() {
        UIPasteboard.general.string = "struct GeneratedModel: Codable {\n    // Implementation derived from JSON\n}"
    }

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
