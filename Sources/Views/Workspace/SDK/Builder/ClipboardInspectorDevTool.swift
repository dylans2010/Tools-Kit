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
            Section("Live Buffer") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(viewModel.contentType, systemImage: viewModel.contentIcon)
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("\(viewModel.currentContent.count) chars").font(.system(size: 8)).foregroundStyle(.tertiary)
                    }

                    Text(viewModel.currentContent)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    HStack {
                        Button { UIPasteboard.general.string = "" ; viewModel.refresh() } label: {
                            Label("Clear", systemImage: "trash")
                        }
                        .buttonStyle(.bordered).controlSize(.small)

                        Spacer()

                        Button { viewModel.refresh() } label: {
                            Label("Force Sync", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent).controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("History Tracking") {
                if viewModel.history.isEmpty {
                    Text("No history recorded yet").font(.caption2).foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.history) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.caption.bold()).lineLimit(1)
                                Text(item.timestamp, style: .time).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button {
                                UIPasteboard.general.string = item.title
                                viewModel.refresh()
                            } label: {
                                Image(systemName: "doc.on.doc").font(.caption2)
                            }
                        }
                    }
                    .onDelete { viewModel.history.remove(atOffsets: $0) }
                }
            }

            Section("Security Settings") {
                Toggle("Auto-clear on background", isOn: .constant(false))
                Toggle("Identify sensitive patterns", isOn: .constant(true))
            }
        }
        .navigationTitle("Clipboard")
        .refreshable { viewModel.refresh() }
        .onAppear { viewModel.refresh() }
    }
}

class ClipboardInspectorViewModel: ObservableObject {
    @Published var currentContent = "Buffer Empty"
    @Published var contentType = "PLAIN TEXT"
    @Published var contentIcon = "doc.text"
    @Published var history: [HistoryItem] = []

    func refresh() {
        if let text = UIPasteboard.general.string, !text.isEmpty {
            currentContent = text
            detectType(text)
            if history.first?.title != text {
                history.insert(HistoryItem(title: text, detail: "Captured"), at: 0)
            }
        } else {
            currentContent = "Buffer Empty"
            contentType = "NONE"
            contentIcon = "doc.text"
        }
    }

    private func detectType(_ text: String) {
        if text.starts(with: "http") {
            contentType = "URL"
            contentIcon = "link"
        } else if text.contains("{") && text.contains("}") {
            contentType = "JSON"
            contentIcon = "curlybraces"
        } else if text.range(of: "^[0-9a-fA-F]{2,}$", options: .regularExpression) != nil {
            contentType = "HEX"
            contentIcon = "number"
        } else {
            contentType = "PLAIN TEXT"
            contentIcon = "text.alignleft"
        }
    }
}

#Preview {
    ClipboardInspectorView()
}
