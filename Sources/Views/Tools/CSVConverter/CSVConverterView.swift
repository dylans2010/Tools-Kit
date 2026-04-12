import SwiftUI

struct CSVConverterView: View {
    @StateObject private var backend = CSVConverterBackend()
    @State private var input: String = "name,email\nJohn Doe,john@example.com"

    var body: some View {
        ToolDetailView(tool: CSVConverterTool()) {
            VStack(spacing: 24) {
                ToolInputSection("CSV Input") {
                    TextEditor(text: $input)
                        .frame(height: 150)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                }

                Button("Convert to JSON") {
                    backend.convertToJSON(csv: input)
                }
                .buttonStyle(.borderedProminent)

                if !backend.output.isEmpty {
                    ToolOutputView("JSON Result", value: backend.output)
                }
            }
        }
    }
}

struct CSVConverterTool: Tool {
    let name = "CSV Converter"
    let icon = "tablecells"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Convert CSV data to structured JSON format"
    let requiresAPI = false
    var view: AnyView { AnyView(CSVConverterView()) }
}
