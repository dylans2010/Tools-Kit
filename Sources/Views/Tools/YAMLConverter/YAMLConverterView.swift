import SwiftUI

struct YAMLConverterView: View {
    @StateObject private var backend = YAMLConverterBackend()
    @State private var input: String = ""

    var body: some View {
        ToolDetailView(tool: YAMLConverterTool()) {
            VStack(spacing: 24) {
                ToolInputSection("YAML Input") {
                    TextEditor(text: $input)
                        .frame(height: 200)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                }

                Button("Convert to JSON") {
                    backend.convertToJSON(yaml: input)
                }
                .buttonStyle(.borderedProminent)

                if !backend.output.isEmpty {
                    ToolOutputView("JSON Output", value: backend.output)
                }
            }
        }
    }
}

struct YAMLConverterTool: Tool {
    let name = "YAML Converter"
    let icon = "doc.text.below.ecg"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Convert between YAML and JSON formats"
    let requiresAPI = false
    var view: AnyView { AnyView(YAMLConverterView()) }
}
