import SwiftUI

struct LoremIpsumGeneratorDevTool: DevTool {
    let id = "lorem-ipsum-generator"
    let name = "Lorem Ipsum Generator"
    let category = DevToolCategory.utilities
    let icon = "text.alignleft"
    let description = "Generate placeholder text"

    func render() -> some View {
        LoremIpsumGeneratorView()
    }
}

struct LoremIpsumGeneratorView: View {
    @StateObject private var viewModel = LoremIpsumGeneratorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Lorem Ipsum Generator",
                description: "Generate mock paragraphs or sentences for UI prototyping and design testing.",
                icon: "text.alignleft"
            )
            .padding()

            Form {
                Section("Configuration") {
                    Stepper("Paragraphs: \(viewModel.paragraphs)", value: $viewModel.paragraphs, in: 1...10)
                    Button("Generate") { viewModel.generate() }
                }

                Section("Result") {
                    TextEditor(text: .constant(viewModel.output))
                        .frame(height: 200)
                        .font(.system(.body))

                    ExportPanel(content: viewModel.output, filename: "lorem_ipsum.txt")
                }
            }
        }
    }
}

class LoremIpsumGeneratorViewModel: ObservableObject {
    @Published var paragraphs = 3
    @Published var output = ""

    func generate() {
        let text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\n\n"
        output = String(repeating: text, count: paragraphs)
    }
}
