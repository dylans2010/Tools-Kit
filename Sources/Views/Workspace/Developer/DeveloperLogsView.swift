import SwiftUI

struct DeveloperLogsView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @State private var filterCategory: LogCategory?
    @State private var filterSeverity: LogSeverity?
    @State private var searchText = ""
    @State private var showingExportSheet = false
    @State private var exportURL: URL?

    var filteredLogs: [LogEntry] {
        logService.logEntries.filter { entry in
            (filterCategory == nil || entry.category == filterCategory) &&
            (filterSeverity == nil || entry.severity == filterSeverity) &&
            (searchText.isEmpty || entry.message.localizedCaseInsensitiveContains(searchText) || entry.source.component.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            logFilterBar

            List {
                if filteredLogs.isEmpty {
                    EmptyStateView(icon: "list.bullet.rectangle.fill", title: "No Logs Found", message: "No log entries match the current filters.")
                        .padding(.vertical, 40)
                } else {
                    ForEach(filteredLogs) { entry in
                        logRow(entry)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("System Logs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportLogs()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(item: $exportURL) { url in
            LogActivityView(activityItems: [url])
        }
    }

    private var logFilterBar: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass").font(.caption).foregroundStyle(.secondary)
                TextField("Search logs...", text: $searchText)
                    .font(.subheadline)
            }
            .padding(10)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 8) {
                Menu {
                    Button("All Categories") { filterCategory = nil }
                    ForEach(LogCategory.allCases, id: \.self) { cat in
                        Button(cat.rawValue) { filterCategory = cat }
                    }
                } label: {
                    HStack {
                        Text(filterCategory?.rawValue ?? "Category").font(.caption.bold())
                        Image(systemName: "chevron.down").font(.system(size: 8))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(filterCategory == nil ? Color.primary.opacity(0.05) : Color.accentColor.opacity(0.1))
                    .foregroundStyle(filterCategory == nil ? .secondary : .accentColor)
                    .clipShape(Capsule())
                }

                Menu {
                    Button("All Severities") { filterSeverity = nil }
                    ForEach(LogSeverity.allCases, id: \.self) { sev in
                        Button(sev.rawValue) { filterSeverity = sev }
                    }
                } label: {
                    HStack {
                        Text(filterSeverity?.rawValue ?? "Severity").font(.caption.bold())
                        Image(systemName: "chevron.down").font(.system(size: 8))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(filterSeverity == nil ? Color.primary.opacity(0.05) : severityColor(filterSeverity!).opacity(0.1))
                    .foregroundStyle(filterSeverity == nil ? .secondary : severityColor(filterSeverity!))
                    .clipShape(Capsule())
                }

                Spacer()

                Text("\(filteredLogs.count) entries").font(.system(size: 9, weight: .bold)).foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func logRow(_ entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(entry.message)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(entry.severity == .critical || entry.severity == .error ? .red : .primary)
                Spacer()
                Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 8) {
                Text(entry.category.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 3))
                    .foregroundStyle(.secondary)

                Text(entry.source.component)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.tertiary)

                Spacer()

                severityBadge(entry.severity)
            }
        }
        .padding(.vertical, 8)
    }

    private func severityBadge(_ severity: LogSeverity) -> some View {
        Circle().fill(severityColor(severity)).frame(width: 6, height: 6)
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

    private func exportLogs() {
        Task {
            let logStrings = filteredLogs.map { "[\($0.timestamp.formatted())] [\($0.severity.rawValue)] [\($0.category.rawValue)] \($0.source.component): \($0.message)" }
            let content = logStrings.joined(separator: "\n")
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("logs_export_\(Date().timeIntervalSince1970).txt")
            try? content.write(to: fileURL, atomically: true, encoding: .utf8)
            await MainActor.run { exportURL = fileURL }
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

struct LogActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
