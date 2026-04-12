import SwiftUI

struct HTMLEntityView: View {
    @StateObject private var backend = HTMLEntityBackend()
    @State private var input: String = ""

    var body: some View {
        ToolDetailView(tool: HTMLEntityTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Input Text") {
                    TextEditor(text: $input)
                        .frame(height: 150)
                        .padding(8)
                }

                HStack {
                    Button("Encode") { backend.encode(input) }.buttonStyle(.bordered)
                    Button("Decode") { backend.decode(input) }.buttonStyle(.bordered)
                }

                if !backend.output.isEmpty {
                    ToolOutputView("Result", value: backend.output)
                }
            }
        }
    }
}

struct HTMLEntityTool: Tool {
    let name = "HTML Entities"
    let icon = "chevron.left.forwardslash.chevron.right"
    let category = ToolCategory.development
    let complexity = ToolComplexity.basic
    let description = "Encode and decode HTML entities safely"
    let requiresAPI = false
    var view: AnyView { AnyView(HTMLEntityView()) }
}
