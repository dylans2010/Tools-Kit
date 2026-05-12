import SwiftUI

struct CURLConverterView: View {
    @StateObject private var backend = CURLConverterBackend()
    @State private var input: String = ""

    var body: some View {
        ToolDetailView(tool: CURLConverterTool()) {
            VStack(spacing: 24) {
                ToolInputSection("cURL Command") {
                    TextEditor(text: $input)
                        .frame(height: 150)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                }

                Button("Generate Swift Code") {
                    backend.convert(curl: input)
                }
                .buttonStyle(.borderedProminent)

                if !backend.swiftCode.isEmpty {
                    ToolOutputView("Swift (URLSession)", value: backend.swiftCode)
                }
            }
        }
    }
}

struct CURLConverterTool: Tool, Sendable {
    let name = "cURL to Code"
    let icon = "terminal"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Convert cURL commands into native Swift networking code"
    let requiresAPI = false
    var view: AnyView { AnyView(CURLConverterView()) }
}
