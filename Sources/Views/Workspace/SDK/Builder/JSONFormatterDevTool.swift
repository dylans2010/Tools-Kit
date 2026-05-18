import SwiftUI

struct JSONFormatterDevTool: View, DevTool {
    let id = "json-formatter"
    let name = "JSON Formatter"
    let category = DevToolCategory.data
    let icon = "text.badge.checkmark"
    let description = "Prettify and minify JSON data"

    func render() -> some View {
        self
    }

    @StateObject private var viewModel = JSONFormatterViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "JSON Formatter",
                description: "Clean up messy JSON, minify it for transmission, or format it for readability.",
                icon: "text.badge.checkmark"
            )
            .padding()

            Form {
                Section("Input") {
                    TextEditor(text: $viewModel.input)
                        .frame(height: 150)
                        .font(.system(.caption, design: .monospaced))
                }

                Section("Options") {
                    Picker("Format", selection: $viewModel.formatType) {
                        Text("Prettify").tag(JSONFormatType.prettify)
                        Text("Minify").tag(JSONFormatType.minify)
                    }
                    .pickerStyle(.segmented)

                    Stepper("Indentation: \(viewModel.indentSize)", value: $viewModel.indentSize, in: 1...8)
                        .disabled(viewModel.formatType == .minify)
                }

                Section("Output") {
                    JSONView(json: viewModel.output)
                        .frame(minHeight: 200)

                    ExportPanel(content: viewModel.output, filename: "formatted.json")
                }
            }
        }
    }
}

enum JSONFormatType {
    case prettify, minify
}

class JSONFormatterViewModel: ObservableObject {
    @Published var input = "{\"id\":1,\"name\":\"Test\",\"tags\":[\"swift\",\"ios\"]}" {
        didSet { process() }
    }
    @Published var output = ""
    @Published var formatType = JSONFormatType.prettify {
        didSet { process() }
    }
    @Published var indentSize = 2 {
        didSet { process() }
    }

    private func process() {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            output = "Invalid JSON"
            return
        }

        let options: JSONSerialization.WritingOptions = formatType == .prettify ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]

        if let formattedData = try? JSONSerialization.data(withJSONObject: json, options: options),
           let result = String(data: formattedData, encoding: .utf8) {
            output = result
        }
    }
}
