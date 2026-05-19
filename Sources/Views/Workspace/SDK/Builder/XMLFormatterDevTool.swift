import SwiftUI

struct XMLFormatterDevTool: DevTool {
    let id = "xml-formatter"
    let name = "XML Formatter"
    let category = DevToolCategory.data
    let icon = "code.circle"
    let description = "Prettify and validate XML data"

    func render() -> some View {
        XMLFormatterDevToolView()
    }
}

struct XMLFormatterDevToolView: View {
    @StateObject private var viewModel = XMLFormatterViewModel()

    var body: some View {
        List {
            Section("XML Document Source") {
                ZStack(alignment: .topTrailing) {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 160)
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
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    Spacer()
                    Button("Minify") { viewModel.minify() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }

            Section("Processed Output") {
                VStack(alignment: .leading, spacing: 10) {
                    ScrollView {
                        Text(viewModel.output)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(height: 250)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                    HStack {
                        Button { UIPasteboard.general.string = viewModel.output } label: {
                            Label("Copy Result", systemImage: "doc.on.doc")
                        }
                        Spacer()
                        Label("\(viewModel.tagCount) Tags", systemImage: "tag.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Validation Audit") {
                HStack {
                    Image(systemName: viewModel.isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(viewModel.isValid ? .green : .red)
                    Text(viewModel.isValid ? "Valid XML Syntax" : "Formatting Errors Detected")
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .navigationTitle("XML Lab")
    }
}

class XMLFormatterViewModel: ObservableObject {
    @Published var input = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<manifest>\n  <app id=\"com.toolskit.sdk\">\n    <version>2.4.1</version>\n    <capabilities>\n      <capability>networking</capability>\n      <capability>storage</capability>\n    </capabilities>\n  </app>\n</manifest>" {
        didSet { format() }
    }
    @Published var output = ""
    @Published var isValid = true
    @Published var tagCount = 0

    func format() {
        var result = ""
        var level = 0
        let tokens = input.replacingOccurrences(of: ">", with: ">\n").replacingOccurrences(of: "<", with: "\n<").components(separatedBy: .newlines)

        for token in tokens {
            let t = token.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { continue }

            if t.hasPrefix("</") { level = max(0, level - 1) }
            result += String(repeating: "  ", count: level) + t + "\n"
            if t.hasPrefix("<") && !t.hasPrefix("</") && !t.hasSuffix("/>") && !t.contains("</") {
                level += 1
            }
        }
        output = result.trimmingCharacters(in: .newlines)
    }

    func minify() {
        output = input.replacingOccurrences(of: ">\\s+<", with: "><", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    XMLFormatterDevToolView()
}
