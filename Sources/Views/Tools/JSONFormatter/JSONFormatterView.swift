import SwiftUI

struct JSONFormatterView: View {
    @StateObject private var backend = JSONFormatterBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TextEditor(text: $backend.inputText)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .border(backend.isValid ? Color.gray : Color.red, width: 1)

                Button("Format and Validate") {
                    backend.format()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                TextEditor(text: .constant(backend.outputText))
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .border(Color.blue, width: 1)

                if !backend.isValid {
                    Text("Invalid JSON format")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("JSON Formatter/Validator")
    }
}

struct JSONFormatterTool: Tool {
    let name = "JSON Formatter"
    let icon = "chevron.left.forwardslash.chevron.right"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Format and validate JSON data"
    let requiresAPI = false

    var view: AnyView {
        AnyView(JSONFormatterView())
    }
}
