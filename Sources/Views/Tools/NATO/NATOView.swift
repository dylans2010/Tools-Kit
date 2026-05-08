import SwiftUI

struct NATOView: View {
    @StateObject private var backend = NATOBackend()
    @State private var input: String = ""

    var body: some View {
        ToolDetailView(tool: NATOTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Text Input") {
                    TextField("Enter word or name", text: $input)
                        .padding()
                        .onChange(of: input) { _, _ in backend.translate(input) }
                }

                if !backend.output.isEmpty {
                    ToolOutputView("NATO Phonetic", value: backend.output)
                }
            }
        }
    }
}

struct NATOTool: Tool {
    let name = "NATO Alphabet"
    let icon = "text.bubble"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Convert text to NATO phonetic alphabet for clear communication"
    let requiresAPI = false
    var view: AnyView { AnyView(NATOView()) }
}
