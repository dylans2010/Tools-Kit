/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style with .searchable integration.
 - Modernized log entries with semantic badges, monospaced typography, and clear source labels.
 - Replaced manual filter and stat bar layouts with native List sections and ToolbarItems.
 - Standardized log level filtering using a native Menu/Picker interface.
 - strictly preserved all SDKLogStore data integration and clearing logic.
 - Improved visual hierarchy for timestamps and multi-line message content.
 */

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
                    Text("System Activity")
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
                Button("Clear", role: .destructive) { logStore.clear() }
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
                .foregroundStyle(selectedLevel == nil ? .secondary : .accentColor)
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
