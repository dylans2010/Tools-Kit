import SwiftUI

struct PlaceholderGeneratorView: View {
    @StateObject private var backend = PlaceholderGeneratorBackend()
    @State private var paragraphs: Double = 1

    var body: some View {
        ToolDetailView(tool: PlaceholderGeneratorTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Paragraphs") {
                    VStack {
                        HStack {
                            Text("Count: \(Int(paragraphs))")
                            Spacer()
                        }
                        Slider(value: $paragraphs, in: 1...10, step: 1)
                    }
                    .padding()
                }

                Button("Generate Lorem Ipsum") {
                    backend.generate(paragraphs: Int(paragraphs))
                }
                .buttonStyle(.borderedProminent)

                if !backend.text.isEmpty {
                    ToolOutputView("Result", value: backend.text)
                }
            }
        }
    }
}

struct PlaceholderGeneratorTool: Tool, Sendable {
    let name = "Placeholder Data"
    let icon = "text.badge.plus"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Generate Lorem Ipsum placeholder text for designs and prototypes"
    let requiresAPI = false
    var view: AnyView { AnyView(PlaceholderGeneratorView()) }
}
