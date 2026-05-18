import SwiftUI

struct ClipboardInspectorDevTool: DevTool {
    let id = "clipboard-inspector"
    let name = "Clipboard Inspector"
    let category = DevToolCategory.utilities
    let icon = "clipboard"
    let description = "View current clipboard content"

    func render() -> some View {
        ClipboardInspectorView()
    }
}

struct ClipboardInspectorView: View {
    @State private var content = ""

    var body: some View {
        Form {
            Section("Current Content") {
                Text(content.isEmpty ? "Clipboard is empty" : content)
                    .font(.monospaced(.body)())
                Button("Refresh") {
                    content = UIPasteboard.general.string ?? ""
                }
            }
        }
        .onAppear {
            content = UIPasteboard.general.string ?? ""
        }
    }
}
