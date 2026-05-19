import SwiftUI

struct TextCaseConverterDevTool: DevTool {
    let id = "text-case-converter"
    let name = "Text Case Converter"
    let category = DevToolCategory.utilities
    let icon = "textformat.abc"
    let description = "Transform text between case formats"

    func render() -> some View {
        TextCaseConverterView()
    }
}

struct TextCaseConverterView: View {
    @StateObject private var viewModel = TextCaseConverterViewModel()

    var body: some View {
        Form {
            Section("Input") {
                TextEditor(text: $viewModel.input)
                    .frame(height: 100)
            }

            Section("Transformed") {
                VStack(alignment: .leading, spacing: 12) {
                    caseRow(title: "UPPERCASE", value: viewModel.input.uppercased())
                    caseRow(title: "lowercase", value: viewModel.input.lowercased())
                    caseRow(title: "Capitalized", value: viewModel.input.capitalized)
                    caseRow(title: "snake_case", value: viewModel.toSnakeCase())
                    caseRow(title: "CamelCase", value: viewModel.toCamelCase())
                }
            }
        }
    }

    private func caseRow(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title).font(.caption2.bold()).foregroundStyle(.secondary)
                Text(value).font(.subheadline).textSelection(.enabled)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = value
            } label: {
                Image(systemName: "doc.on.doc").font(.caption)
            }
        }
    }
}

class TextCaseConverterViewModel: ObservableObject {
    @Published var input = "Hello World"

    func toSnakeCase() -> String {
        input.lowercased().replacingOccurrences(of: " ", with: "_")
    }

    func toCamelCase() -> String {
        input.capitalized.replacingOccurrences(of: " ", with: "")
    }
}

#Preview {
    TextCaseConverterView()
}
