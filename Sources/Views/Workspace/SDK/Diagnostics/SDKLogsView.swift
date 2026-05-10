

import SwiftUI

struct SDKLogsView: View {
    @StateObject private var logStore = SDKLogStore.shared
    @State private var selectedLevel: LogLevel?
    @State private var searchText = ""

    private var filteredEntries: [SDKLogEntry] {
        logStore.entries.filter { entry in
            (selectedLevel == nil || entry.level == selectedLevel) &&
            (searchText.isEmpty || entry.source.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(filteredEntries) { entry in
                    SystemLogRow(entry: entry)
                }
            } header: {
                HStack {
                    Label("System Activity", systemImage: "list.bullet.rectangle")
                    Spacer()
                    Text("\(filteredEntries.count) events").font(.caption2.monospaced())
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Filter by source")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                levelFilterMenu
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) { logStore.clear() } label: {
                    Label("Clear", systemImage: "trash")
                }
            }
        }
    }

    private var levelFilterMenu: some View {
        Menu {
            Picker("Log Level", selection: $selectedLevel) {
                Text("All Levels").tag(LogLevel?.none)
                ForEach(LogLevel.allCases, id: \.self) { Text($0.rawValue.capitalized).tag(LogLevel?.some($0)) }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(selectedLevel == nil ? Color.secondary : Color.accentColor)
        }
    }
}

// MARK: - Private Subviews

private struct SystemLogRow: View {
    let entry: SDKLogEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.level.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                    .foregroundStyle(color)

                Text(entry.source).font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened)).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
            }
            Text(entry.message).font(.caption.monospaced()).foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
    private var color: Color {
        switch entry.level { case .debug: return .secondary; case .info: return .blue; case .warning: return .orange; case .error: return .red }
    }
}
