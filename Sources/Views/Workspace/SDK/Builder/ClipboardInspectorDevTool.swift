import SwiftUI

struct ClipboardInspectorDevTool: DevTool {
    let id = "clipboard-inspector"
    let name = "Clipboard Inspector"
    let category = DevToolCategory.utilities
    let icon = "list.bullet.clipboard"
    let description = "View and manage clipboard contents"

    func render() -> some View {
        ClipboardInspectorView()
    }
}

struct ClipboardInspectorView: View {
    @StateObject private var viewModel = ClipboardInspectorViewModel()

    var body: some View {
        List {
            Section("Current Clipboard") {
                Text(viewModel.currentContent)
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                    .textSelection(.enabled)
            }

            Section("History") {
                ForEach(viewModel.history) { item in
                    VStack(alignment: .leading) {
                        Text(item.title).font(.caption.bold())
                        Text(item.timestamp, style: .time).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .refreshable { viewModel.refresh() }
        .onAppear { viewModel.refresh() }
    }
}

class ClipboardInspectorViewModel: ObservableObject {
    @Published var currentContent = "No text in clipboard"
    @Published var history: [HistoryItem] = []

    func refresh() {
        if let text = UIPasteboard.general.string {
            currentContent = text
            if history.first?.title != text {
                history.insert(HistoryItem(title: text, detail: "Copied"), at: 0)
            }
        }
    }
}

#Preview {
    ClipboardInspectorView()
}
