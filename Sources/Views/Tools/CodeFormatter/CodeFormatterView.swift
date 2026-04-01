import SwiftUI

struct CodeFormatterView: View {
    @StateObject private var backend = CodeFormatterBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Language", selection: $backend.selectedLanguage) {
                    ForEach(backend.languages, id: \.self) { lang in
                        Text(lang).tag(lang)
                    }
                }
                .pickerStyle(.segmented)

                TextEditor(text: $backend.inputText)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .border(Color.gray, width: 1)

                Button("Format Code") {
                    backend.format()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                TextEditor(text: .constant(backend.formattedText))
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .border(Color.blue, width: 1)
            }
            .padding()
        }
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
