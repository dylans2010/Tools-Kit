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
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Manage your clipboard history. You can save snippets, search through them, and mark your favorites for quick access.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("New entry or search...", text: $textToCopy)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: {
                        backend.copyToClipboard(textToCopy)
                        textToCopy = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(textToCopy.isEmpty)
                }

                HStack {
                    TextField("Search history...", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)

                    Toggle(isOn: $showFavoritesOnly) {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    .toggleStyle(.button)
                    .labelsHidden()
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))

            List {
                if filteredHistory.isEmpty {
                    ContentUnavailableView("No Results", systemImage: "doc.on.clipboard", description: Text("No clipboard entries found matching your criteria."))
                } else {
                    ForEach(filteredHistory) { entry in
                        ClipboardEntryRow(entry: entry, backend: backend)
                    }
                    .onDelete(perform: backend.deleteEntry)
                }
            }
            .listStyle(InsetGroupedListStyle())

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
                .padding()
            }
        }
        .navigationTitle("Clipboard Manager")
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
