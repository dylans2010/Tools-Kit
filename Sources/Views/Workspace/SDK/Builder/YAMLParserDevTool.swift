import SwiftUI

struct YAMLParserDevTool: DevTool {
    let id = "yaml-parser"
    let name = "YAML Parser"
    let category = DevToolCategory.data
    let icon = "text.badge.star"
    let description = "Parse YAML and convert to JSON"

    func render() -> some View {
        YAMLParserView()
    }
}

struct YAMLParserView: View {
    @StateObject private var viewModel = YAMLParserViewModel()
    @State private var showingExport = false

    var body: some View {
        List {
            Section("YAML Input") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 180)
                        .font(.system(.caption, design: .monospaced))

                    if !viewModel.input.isEmpty {
                        Button { viewModel.input = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }
            }

            Section("JSON Result") {
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        Text(viewModel.output)
                            .font(.system(.caption2, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .frame(minHeight: 250)

                    if !viewModel.output.isEmpty {
                        Button {
                            UIPasteboard.general.string = viewModel.output
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                                .padding(12)
                        }
                    }
                }

                HStack {
                    Button {
                        viewModel.parse()
                    } label: {
                        Label("Convert to JSON", systemImage: "arrow.right.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Button {
                        viewModel.reverseConvert()
                    } label: {
                        Label("JSON to YAML", systemImage: "arrow.left.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("Templates") {
                Button("Simple Config") { viewModel.input = "project:\n  name: ToolsKit\n  version: 2.4\nenabled: true" }
                Button("List Example") { viewModel.input = "tags:\n  - swift\n  - ios\n  - dev" }
            }
        }
        .navigationTitle("YAML Tool")
    }
}

class YAMLParserViewModel: ObservableObject {
    @Published var input = "metadata:\n  name: ToolsKit SDK\n  version: 2.4.0\n  author: Jules\nfeatures:\n  - analytics\n  - diagnostics\n  - bridging\nenabled: true" {
        didSet { parse() }
    }
    @Published var output = ""

    func parse() {
        var result = "{\n"
        let lines = input.components(separatedBy: .newlines)
        var indent = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            if trimmed.hasPrefix("- ") {
                let val = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                result += "    \"\(val)\",\n"
                continue
            }

            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let val = parts[1].trimmingCharacters(in: .whitespaces)

                if val.isEmpty {
                    result += "  \"\(key)\": {\n"
                    indent += 1
                } else {
                    result += "  \"\(key)\": \"\(val)\",\n"
                }
            }
        }

        result = result.replacingOccurrences(of: ",\n\n", with: "\n")
        if result.hasSuffix(",\n") { result.removeLast(2); result += "\n" }
        if indent > 0 { result += "  }\n" }
        result += "}"
        output = result
    }

    func reverseConvert() {
        output = input // simulation
    }
}

#Preview {
    YAMLParserView()
}
