import SwiftUI

struct DeveloperLogsView: View {
    @ObservedObject var logService = DeveloperLogService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var searchText = ""
    @State private var selectedSeverity: LogSeverity?
    @State private var selectedCategory: LogCategory?
    @State private var selectedAppID: UUID?
    @State private var showingExportSheet = false
    @State private var exportURL: URL?

    var filteredLogs: [LogEntry] {
        logService.logEntries.filter { entry in
            (searchText.isEmpty || entry.message.localizedCaseInsensitiveContains(searchText) || entry.payload.localizedCaseInsensitiveContains(searchText)) &&
            (selectedSeverity == nil || entry.severity == selectedSeverity) &&
            (selectedCategory == nil || entry.category == selectedCategory)
            // && (selectedAppID == nil || entry.sourceAppID == selectedAppID)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            List {
                if filteredLogs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No logs found.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(filteredLogs) { entry in
                        logRow(entry)
                    }
                }
            }
            .listStyle(.plain)
        }
        .searchable(text: $searchText, prompt: "Search message, payload, or correlation ID")
        .navigationTitle("Developer Logs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportLogs()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                LogActivityView(activityItems: [url])
            }
        }
        .refreshable {
            logService.loadLogEntries()
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Picker("Severity", selection: $selectedSeverity) {
                    Text("Severity: All").tag(Optional<LogSeverity>.none)
                    ForEach(LogSeverity.allCases, id: \.self) { severity in
                        Text(severity.rawValue).tag(Optional(severity))
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                .background(Color.secondary.opacity(0.1), in: Capsule())

                Picker("Category", selection: $selectedCategory) {
                    Text("Category: All").tag(Optional<LogCategory>.none)
                    ForEach(LogCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(Optional(category))
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                .background(Color.secondary.opacity(0.1), in: Capsule())

                Picker("Project", selection: $selectedAppID) {
                    Text("Project: All").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                .background(Color.secondary.opacity(0.1), in: Capsule())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private func logRow(_ entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.severity.rawValue)
                    .font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(severityColor(entry.severity).opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(severityColor(entry.severity))

                Text(entry.category.rawValue).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                Spacer()
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened)).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
            }

            Text(entry.message).font(.subheadline)

            if !entry.payload.isEmpty {
                DisclosureGroup {
                    Text(entry.payload)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } label: {
                    Text("View Details").font(.caption2).foregroundColor(.accentColor)
                }
            }

            HStack {
                Text("Source: \(entry.source.component)").font(.system(size: 8)).foregroundStyle(.tertiary)
                if !entry.correlationID.isEmpty {
                    Spacer()
                    Text("ID: \(entry.correlationID)").font(.system(size: 8)).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 8)
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
            let url = try? await logService.exportLogs(format: "json", filters: [:])
            await MainActor.run {
                exportURL = url
                showingExportSheet = true
            }
        }
    }
}

struct LogActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
