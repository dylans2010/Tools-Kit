import SwiftUI

struct JSONFormatterDevTool: DevTool {
    let id = "json-formatter"
    let name = "JSON Formatter"
    let category = DevToolCategory.data
    let icon = "text.badge.checkmark"
    let description = "Prettify and minify JSON data"

    func render() -> some View {
        JSONFormatterDevToolView()
    }
}

struct JSONFormatterDevToolView: View {
    @StateObject private var viewModel = JSONFormatterViewModel()

    var body: some View {
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
                ScrollView {
                    Text(viewModel.output)
                        .font(.system(.caption2, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(8)
                .frame(minHeight: 200)

                HStack {
                    Button {
                        UIPasteboard.general.string = viewModel.output
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        let tempDir = FileManager.default.temporaryDirectory
                        let fileURL = tempDir.appendingPathComponent("formatted.json")
                        try? viewModel.output.write(to: fileURL, atomically: true, encoding: .utf8)
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
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

#Preview {
    JSONFormatterDevToolView()
}
