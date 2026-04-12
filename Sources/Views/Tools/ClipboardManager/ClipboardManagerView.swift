import SwiftUI

struct ClipboardManagerView: View {
    @StateObject private var backend = ClipboardManagerBackend()
    @State private var textToCopy = ""
    @State private var searchQuery = ""
    @State private var showFavoritesOnly = false

    var filteredHistory: [ClipboardEntry] {
        backend.history.filter { entry in
            (searchQuery.isEmpty || entry.content.localizedCaseInsensitiveContains(searchQuery)) &&
            (!showFavoritesOnly || entry.isFavorite)
        }
    }

    var body: some View {
        ToolDetailView(tool: ClipboardManagerTool()) {
            VStack(spacing: 16) {
                ToolInputSection("Quick Add") {
                    HStack {
                        TextField("Type text to save to clipboard", text: $textToCopy)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            backend.copyToClipboard(textToCopy)
                            textToCopy = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(textToCopy.isEmpty)
                    }
                    .padding()
                }

                ToolInputSection("Filters") {
                    HStack {
                        TextField("Search history...", text: $searchQuery)
                            .textFieldStyle(.roundedBorder)
                        Toggle(isOn: $showFavoritesOnly) {
                            Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        .toggleStyle(.button)
                        .labelsHidden()
                    }
                    .padding()
                }

                ToolInputSection("History") {
                    if filteredHistory.isEmpty {
                        ContentUnavailableView("No Results", systemImage: "doc.on.clipboard", description: Text("No clipboard entries found matching your criteria."))
                            .padding()
                    } else {
                        ForEach(filteredHistory) { entry in
                            ClipboardEntryRow(entry: entry, backend: backend)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            if entry.id != filteredHistory.last?.id { Divider() }
                        }
                    }
                }

                if !backend.history.isEmpty {
                    HStack {
                        Button(action: backend.clearHistory) {
                            Label("Clear All", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        Spacer()
                        Text("\(backend.history.count) entries")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct ClipboardEntryRow: View {
    let entry: ClipboardEntry
    @ObservedObject var backend: ClipboardManagerBackend

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.content)
                .lineLimit(4)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.primary)

            HStack {
                Text(entry.timestamp, style: .date)
                Text(entry.timestamp, style: .time)

                Spacer()

                HStack(spacing: 16) {
                    Button(action: { backend.toggleFavorite(entry) }) {
                        Image(systemName: entry.isFavorite ? "star.fill" : "star")
                            .foregroundColor(entry.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: { UIPasteboard.general.string = entry.content }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ClipboardManagerTool: Tool {
    let name = "Clipboard Manager"
    let icon = "paperclip"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Keep track of your recently copied text and manage history"
    let requiresAPI = false
    var view: AnyView { AnyView(ClipboardManagerView()) }
}
