import SwiftUI

struct TextCaseConverterDevTool: DevTool {
    let id = "text-case-converter"
    let name = "Text Case Converter"
    let category = DevToolCategory.utilities
    let icon = "textformat"
    let description = "Convert text between various cases"

    func render() -> some View {
        TextCaseConverterView()
    }
}

struct TextCaseConverterView: View {
    @State private var inputText = ""

    var body: some View {
        Form {
            Section("Input Text") {
                TextEditor(text: $inputText)
                    .frame(height: 100)
            }

            Section("Conversions") {
                LabeledContent("UPPERCASE", value: inputText.uppercased())
                LabeledContent("lowercase", value: inputText.lowercased())
                LabeledContent("Capitalized", value: inputText.capitalized)
            }
        }
    }
}
