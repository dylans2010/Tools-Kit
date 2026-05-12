import SwiftUI

struct MorseCodeView: View {
    @StateObject private var backend = MorseCodeBackend()
    @State private var input: String = ""

    var body: some View {
        ToolDetailView(tool: MorseCodeTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Text Input") {
                    TextEditor(text: $input)
                        .frame(height: 100)
                        .padding(8)
                        .onChange(of: input) { _, _ in backend.encode(input) }
                }

                if !backend.output.isEmpty {
                    ToolOutputView("Morse Code", value: backend.output)
                }
            }
        }
    }
}

struct MorseCodeTool: Tool, Sendable {
    let name = "Morse Code"
    let icon = "dot.radiowaves.left.and.right"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Translate text into international Morse code"
    let requiresAPI = false
    var view: AnyView { AnyView(MorseCodeView()) }
}
