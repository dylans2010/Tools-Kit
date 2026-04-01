import SwiftUI

struct NotesFormatterView: View {
    @StateObject private var backend = NotesFormatterBackend()

    var body: some View {
        VStack {
            TextEditor(text: $backend.inputText)
                .frame(maxHeight: 200)
                .border(Color.gray, width: 1)
                .padding()

            HStack {
                Button("ABC") { backend.format(to: .uppercase) }
                Button("abc") { backend.format(to: .lowercase) }
                Button("Abc") { backend.format(to: .capitalized) }
                Button("• Bullets") { backend.format(to: .bulletPoints) }
            }
            .buttonStyle(.bordered)

            TextEditor(text: .constant(backend.formattedText))
                .frame(maxHeight: 200)
                .border(Color.blue, width: 1)
                .padding()
        }
        .navigationTitle("Notes Formatter")
    }
}

struct NotesFormatterTool: Tool {
    let name = "Notes Formatter"
    let icon = "text.badge.plus"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Format and clean up text notes"
    let requiresAPI = false

    var view: AnyView {
        AnyView(NotesFormatterView())
    }
}
