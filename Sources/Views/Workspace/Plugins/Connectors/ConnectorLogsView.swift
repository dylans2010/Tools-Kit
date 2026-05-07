import SwiftUI

struct ConnectorLogsView: View {
    var connectorID: UUID?
    @StateObject private var manager = ConnectorManager.shared
    @State private var filter: LogFilter = .all
    @State private var searchText = ""
    @State private var showingClearAlert = false
    @State private var autoRefreshEnabled = true
    @State private var expandedLogID: UUID?
    @State private var selectedDateRange: DateRange = .all

    enum LogFilter: String, CaseIterable {
        case all = "All"
        case info = "Info"
        case warnings = "Warnings"
        case errors = "Errors"
        case performance = "Performance"
    }

    enum DateRange: String, CaseIterable {
        case all = "All Time"
        case lastHour = "Last Hour"
        case today = "Today"
        case lastWeek = "Last Week"
    }

    var filteredLogs: [ConnectorLog] {
        var base = connectorID == nil ? manager.logs : manager.logs.filter { $0.connectorID == connectorID }

        switch filter {
        case .all: break
        case .info: base = base.filter { $0.type == .info }
        case .warnings: base = base.filter { $0.type == .warning }
        case .errors: base = base.filter { $0.type == .error }
        case .performance: base = base.filter { $0.type == .performance }
        }

        if !searchText.isEmpty {
            base = base.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                ($0.details ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        switch selectedDateRange {
        case .all: break
        case .lastHour: base = base.filter { $0.timestamp > Date().addingTimeInterval(-3600) }
        case .today: base = base.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .lastWeek: base = base.filter { $0.timestamp > Date().addingTimeInterval(-604800) }
        }

        return base.sorted { $0.timestamp > $1.timestamp }
    }

    var logStats: (total: Int, errors: Int, warnings: Int, performance: Int) {
        let base = connectorID == nil ? manager.logs : manager.logs.filter { $0.connectorID == connectorID }
        return (
            total: base.count,
            errors: base.filter { $0.type == .error }.count,
            warnings: base.filter { $0.type == .warning }.count,
            performance: base.filter { $0.type == .performance }.count
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Stats Bar
            HStack(spacing: 16) {
                logStatBadge(label: "Total", value: logStats.total, color: .blue)
                logStatBadge(label: "Errors", value: logStats.errors, color: .red)
                logStatBadge(label: "Warnings", value: logStats.warnings, color: .orange)
                logStatBadge(label: "Perf", value: logStats.performance, color: .purple)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // MARK: - Filters
            VStack(spacing: 8) {
                Picker("Filter", selection: $filter) {
                    ForEach(LogFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                HStack {
                    Picker("Date", selection: $selectedDateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    Toggle(isOn: $autoRefreshEnabled) {
                        Label("Auto-refresh", systemImage: "arrow.clockwise")
                            .font(.caption2)
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)

            // MARK: - Log List
            List {
                if filteredLogs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("No logs found")
                            .font(.headline)
                        Text(searchText.isEmpty ? "No log entries match the current filter." : "No logs match '\(searchText)'.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    ForEach(filteredLogs) { log in
                        logRow(log)
                            .onTapGesture {
                                withAnimation {
                                    expandedLogID = expandedLogID == log.id ? nil : log.id
                                }
                            }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search logs...")
        .navigationTitle(connectorID == nil ? "Global Logs" : "Execution Logs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingClearAlert = true
                    } label: {
                        Label("Clear All Logs", systemImage: "trash")
                    }

                    Button {
                        exportLogs()
                    } label: {
                        Label("Export Logs", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Toggle(isOn: $autoRefreshEnabled) {
                        Label("Auto-Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Clear All Logs?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                if let id = connectorID {
                    manager.clearLogs(for: id)
                } else {
                    manager.clearAllLogs()
                }
            }
        } message: {
            Text("This will permanently remove all log entries. This action cannot be undone.")
        }
    }

    private func logRow(_ log: ConnectorLog) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.type.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(logTypeColor(log.type).opacity(0.15))
                    .foregroundColor(logTypeColor(log.type))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                Text(log.timestamp.formatted(date: .abbreviated, time: .standard))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(log.message)
                .font(.subheadline.bold())

            if let details = log.details {
                Text(details)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(expandedLogID == log.id ? nil : 3)
            }

            if expandedLogID == log.id {
                HStack(spacing: 12) {
                    Label(log.connectorID.uuidString.prefix(8) + "...", systemImage: "puzzlepiece")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Label(log.timestamp.formatted(.relative(presentation: .numeric)), systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)

                Button {
                    UIPasteboard.general.string = formatLogForExport(log)
                } label: {
                    Label("Copy Log Entry", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func logStatBadge(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func logTypeColor(_ type: ConnectorLog.LogType) -> Color {
        switch type {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .performance: return .purple
        }
    }

    private func formatLogForExport(_ log: ConnectorLog) -> String {
        var entry = "[\(log.type.rawValue.uppercased())] \(log.timestamp.formatted())\n\(log.message)"
        if let details = log.details {
            entry += "\n\(details)"
        }
        return entry
    }

    private func exportLogs() {
        let text = filteredLogs.map { formatLogForExport($0) }.joined(separator: "\n---\n")
        UIPasteboard.general.string = text
    }
}
