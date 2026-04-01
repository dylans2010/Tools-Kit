import SwiftUI

struct JSONFormatterView: View {
    @StateObject private var backend = JSONFormatterBackend()

    var body: some View {
        VStack {
            TextEditor(text: $backend.inputText)
                .frame(maxHeight: 200)
                .border(backend.isValid ? Color.gray : Color.red, width: 1)
                .padding()

            Button("Format and Validate") {
                backend.format()
            }
            .buttonStyle(.borderedProminent)

            TextEditor(text: .constant(backend.outputText))
                .frame(maxHeight: 200)
                .border(Color.blue, width: 1)
                .padding()

            if !backend.isValid {
                Text("Invalid JSON format")
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("JSON Formatter/Validator")
    }
}

struct JSONFormatterTool: Tool {
    let name = "JSON Formatter"
    let icon = "chevron.left.forwardslash.chevron.right"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Format and validate JSON data"

    var view: AnyView {
        AnyView(JSONFormatterView())
    }
}
