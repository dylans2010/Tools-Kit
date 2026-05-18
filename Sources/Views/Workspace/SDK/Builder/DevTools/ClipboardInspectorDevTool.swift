import SwiftUI

struct ClipboardInspectorTool: DevTool {
    let id = UUID()
    let name = "Clipboard Inspector"
    let category: DevToolCategory = .utilities
    let icon = "doc.on.clipboard"
    let description = "Inspect clipboard contents and types"
    func render() -> some View { ClipboardInspectorDevToolView() }
}

struct ClipboardInspectorDevToolView: View {
    @State private var clipboardContent = ""
    @State private var clipboardTypes: [String] = []
    @State private var itemCount = 0
    @State private var charCount = 0

    var body: some View {
        Form {
            Section {
                Button("Read Clipboard") { readClipboard() }
                Button("Clear Clipboard") {
                    UIPasteboard.general.string = nil
                    clipboardContent = ""
                    clipboardTypes.removeAll()
                    itemCount = 0
                    charCount = 0
                }
            }
            Section("Info") {
                LabeledContent("Items", value: "\(itemCount)")
                LabeledContent("Characters", value: "\(charCount)")
                LabeledContent("Has Strings", value: UIPasteboard.general.hasStrings ? "Yes" : "No")
                LabeledContent("Has URLs", value: UIPasteboard.general.hasURLs ? "Yes" : "No")
                LabeledContent("Has Images", value: UIPasteboard.general.hasImages ? "Yes" : "No")
            }
            if !clipboardTypes.isEmpty {
                Section("Types") {
                    ForEach(clipboardTypes, id: \.self) { type in
                        Text(type).font(.system(.caption, design: .monospaced))
                    }
                }
            }
            if !clipboardContent.isEmpty {
                Section("Content") {
                    Text(clipboardContent.prefix(2000))
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Clipboard Inspector")
        .onAppear { readClipboard() }
    }

    private func readClipboard() {
        let pb = UIPasteboard.general
        itemCount = pb.numberOfItems
        clipboardTypes = pb.types
        clipboardContent = pb.string ?? ""
        charCount = clipboardContent.count
    }
}
