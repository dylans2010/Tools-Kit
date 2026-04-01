import SwiftUI

struct CodeFormatterView: View {
    @StateObject private var backend = CodeFormatterBackend()

    var body: some View {
        VStack {
            Picker("Language", selection: $backend.selectedLanguage) {
                ForEach(backend.languages, id: \.self) { lang in
                    Text(lang).tag(lang)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            TextEditor(text: $backend.inputText)
                .frame(maxHeight: 200)
                .border(Color.gray, width: 1)
                .padding()

            Button("Format Code") {
                backend.format()
            }
            .buttonStyle(.borderedProminent)

            TextEditor(text: .constant(backend.formattedText))
                .frame(maxHeight: 200)
                .border(Color.blue, width: 1)
                .padding()

            Spacer()
        }
        .padding()
        .navigationTitle("Code Formatter")
    }
}

struct CodeFormatterTool: Tool {
    let name = "Code Formatter"
    let icon = "chevron.left.slash.chevron.right"
    let category = ToolCategory.development
    let complexity = ToolComplexity.advanced
    let description = "Format code for multiple languages"
    let requiresAPI = false

    var view: AnyView {
        AnyView(CodeFormatterView())
    }
}
