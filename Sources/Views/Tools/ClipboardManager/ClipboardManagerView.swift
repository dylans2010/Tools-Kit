import SwiftUI

struct ClipboardManagerView: View {
    @StateObject private var backend = ClipboardManagerBackend()

    var body: some View {
        VStack {
            Text("Clipboard Content:")
                .font(.headline)

            TextEditor(text: $backend.clipboardContent)
                .frame(maxHeight: 200)
                .border(Color.gray, width: 1)
                .padding()

            HStack {
                Button("Copy") {
                    backend.copyToClipboard(backend.clipboardContent)
                }
                Button("Paste") {
                    backend.pasteFromClipboard()
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Clipboard Manager")
    }
}

struct ClipboardManagerTool: Tool {
    let name = "Clipboard Manager"
    let icon = "paperclip"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Manage your clipboard history"

    var view: AnyView {
        AnyView(ClipboardManagerView())
    }
}
