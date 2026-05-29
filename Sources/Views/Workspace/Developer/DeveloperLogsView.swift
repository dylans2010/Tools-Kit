import SwiftUI

struct DeveloperLogsView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @State private var searchText = ""
    @State private var selectedSeverity: LogSeverity?
    @State private var selectedCategory: LogCategory?

    var filteredLogs: [LogEntry] {
        logService.logEntries.filter { entry in
            (searchText.isEmpty || entry.message.localizedCaseInsensitiveContains(searchText) || entry.payload.localizedCaseInsensitiveContains(searchText)) &&
            (selectedSeverity == nil || entry.severity == selectedSeverity) &&
            (selectedCategory == nil || entry.category == selectedCategory)
        }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Picker("Severity", selection: $selectedSeverity) {
                        Text("All").tag(Optional<LogSeverity>.none)
                        ForEach(LogSeverity.allCases, id: \.self) { severity in
                            Text(severity.rawValue).tag(Optional(severity))
                        }
                    }
                    Divider()
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag(Optional<LogCategory>.none)
                        ForEach(LogCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(Optional(category))
                        }
                    }
                }
            }

            Section {
                if filteredLogs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No logs matching the current filters were found.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(filteredLogs) { entry in
                        logRow(entry)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search message or payload")
        .navigationTitle("Developer Logs")
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    Task { try? await logService.exportLogs(format: "json", filters: [:]) }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private func logRow(_ entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.severity.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(severityColor(entry.severity).opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(severityColor(entry.severity))

                Text(entry.category.rawValue).font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened)).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
            }

            Text(entry.message).font(.subheadline)

            if !entry.payload.isEmpty {
                Text(entry.payload)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(4)
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.vertical, 4)
    }

    private func severityColor(_ severity: LogSeverity) -> Color {
        switch severity {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}
