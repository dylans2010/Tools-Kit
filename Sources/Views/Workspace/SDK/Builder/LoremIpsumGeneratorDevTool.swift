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
    @State private var paragraphs = 3.0
    @State private var result = ""

    var body: some View {
        Form {
            Section("Settings") {
                HStack {
                    Text("Paragraphs: \(Int(paragraphs))")
                    Slider(value: $paragraphs, in: 1...10, step: 1)
                }
                Button("Generate") {
                    generate()
                }
            }

            if !result.isEmpty {
                Section("Result") {
                    Text(result)
                        .font(.caption)
                        .textSelection(.enabled)

                    Button {
                        UIPasteboard.general.string = result
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }

    private func generate() {
        let text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        result = Array(repeating: text, count: Int(paragraphs)).joined(separator: "\n\n")
    }
}
