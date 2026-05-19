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
        List {
            Section("Input") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 120)
                        .font(.system(.subheadline))

                    if !viewModel.input.isEmpty {
                        Button { viewModel.input = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }
            }

            Section("Transformations") {
                CaseResultRow(label: "UPPERCASE", value: viewModel.input.uppercased())
                CaseResultRow(label: "lowercase", value: viewModel.input.lowercased())
                CaseResultRow(label: "Capitalized", value: viewModel.input.capitalized)
                CaseResultRow(label: "snake_case", value: viewModel.toSnakeCase())
                CaseResultRow(label: "kebab-case", value: viewModel.toKebabCase())
                CaseResultRow(label: "camelCase", value: viewModel.toCamelCase())
                CaseResultRow(label: "PascalCase", value: viewModel.toPascalCase())
                CaseResultRow(label: "Title Case", value: viewModel.toTitleCase())
            }
        }
        .navigationTitle("Case Converter")
    }
}

struct CaseResultRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                Text(value).font(.subheadline).textSelection(.enabled)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = value
            } label: {
                Image(systemName: "doc.on.doc").font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 2)
    }
}

class TextCaseConverterViewModel: ObservableObject {
    @Published var input = "ToolsKit SDK"

    func toSnakeCase() -> String {
        input.lowercased().replacingOccurrences(of: " ", with: "_")
    }

    func toKebabCase() -> String {
        input.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    func toCamelCase() -> String {
        let words = input.components(separatedBy: .whitespaces)
        guard let first = words.first?.lowercased() else { return "" }
        let rest = words.dropFirst().map { $0.capitalized }
        return ([first] + rest).joined()
    }

    func toPascalCase() -> String {
        input.capitalized.replacingOccurrences(of: " ", with: "")
    }

    func toTitleCase() -> String {
        input.capitalized
    }
}

#Preview {
    TextCaseConverterView()
}
