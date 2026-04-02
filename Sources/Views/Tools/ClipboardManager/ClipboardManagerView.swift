import SwiftUI

struct ClipboardManagerView: View {
    @StateObject private var backend = ClipboardManagerBackend()

    var body: some View {
        VStack(spacing: 16) {
            Text("Clipboard Content:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextEditor(text: $backend.clipboardContent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray, width: 1)

            HStack {
                Button("Copy") {
                    backend.copyToClipboard(backend.clipboardContent)
                }
                Button("Paste") {
                    backend.pasteFromClipboard()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    let requiresAPI = false

    var view: AnyView {
        AnyView(ClipboardManagerView())
    }
}
