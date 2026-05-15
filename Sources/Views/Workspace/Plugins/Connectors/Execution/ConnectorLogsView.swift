

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
            base = base.filter { $0.message.localizedCaseInsensitiveContains(searchText) || ($0.details ?? "").localizedCaseInsensitiveContains(searchText) }
        }
        switch selectedDateRange {
        case .all: break
        case .lastHour: base = base.filter { $0.timestamp > Date().addingTimeInterval(-3600) }
        case .today: base = base.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .lastWeek: base = base.filter { $0.timestamp > Date().addingTimeInterval(-604800) }
        }
        return base.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            StatsBar(manager: manager, connectorID: connectorID)

            VStack(spacing: 12) {
                Picker("Filter", selection: $filter) {
                    ForEach(LogFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                HStack {
                    Picker("Date Range", selection: $selectedDateRange) {
                        ForEach(DateRange.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.menu).controlSize(.small)
                    Spacer()
                    Toggle(isOn: $autoRefreshEnabled) { Label("Live", systemImage: "arrow.clockwise") }.toggleStyle(.button).controlSize(.mini)
                }
            }
            .padding().background(Color(uiColor: .secondarySystemGroupedBackground))

            List {
                if filteredLogs.isEmpty {
                    ContentUnavailableView("No Logs Found", systemImage: "doc.text.magnifyingglass", description: Text("No entries match your current search or filter criteria."))
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredLogs) { log in
                        ConnectorLogLine(log: log, isExpanded: expandedLogID == log.id) {
                            withAnimation { expandedLogID = expandedLogID == log.id ? nil : log.id }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .searchable(text: $searchText, prompt: "Search log entries...")
        .navigationTitle(connectorID == nil ? "System Logs" : "Execution Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) { showingClearAlert = true } label: { Label("Clear Logs", systemImage: "trash") }
                    Button { exportLogs() } label: { Label("Export All", systemImage: "square.and.arrow.up") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .alert("Clear Logs?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { if let id = connectorID { manager.clearLogs(for: id) } else { manager.clearAllLogs() } }
        } message: { Text("This will permanently remove all recorded events for this context.") }
    }

    private func exportLogs() {
        let text = filteredLogs.map { "[\($0.type.rawValue.uppercased())] \($0.timestamp.formatted())\n\($0.message)\($0.details != nil ? "\n\($0.details!)" : "")" }.joined(separator: "\n---\n")
        UIPasteboard.general.string = text
    }
}

// MARK: - Private Subviews

private struct StatsBar: View {
    @ObservedObject var manager: ConnectorManager
    let connectorID: UUID?

    var body: some View {
        let base = connectorID == nil ? manager.logs : manager.logs.filter { $0.connectorID == connectorID }
        HStack(spacing: 0) {
            DetailMetricPill(label: "Total", value: "\(base.count)", color: .blue)
            DetailMetricPill(label: "Errors", value: "\(base.filter { $0.type == .error }.count)", color: .red)
            DetailMetricPill(label: "Warn", value: "\(base.filter { $0.type == .warning }.count)", color: .orange)
            DetailMetricPill(label: "Perf", value: "\(base.filter { $0.type == .performance }.count)", color: .purple)
        }
        .padding(.vertical, 12).background(Color(uiColor: .systemGroupedBackground))
    }
}

private struct ConnectorLogLine: View {
    let log: ConnectorLog
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.type.rawValue.uppercased()).font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(log.type.color.opacity(0.1), in: Capsule()).foregroundStyle(log.type.color)
                Spacer()
                Text(log.timestamp.formatted(date: .omitted, time: .standard)).font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
            Text(log.message).font(.subheadline.bold())
            if let details = log.details {
                Text(details).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).lineLimit(isExpanded ? nil : 2)
            }
            if isExpanded {
                HStack(spacing: 12) {
                    Label(log.connectorID.uuidString.prefix(8) + "...", systemImage: "cable.connector").font(.system(size: 8))
                    Label(log.timestamp.formatted(.relative(presentation: .numeric)), systemImage: "clock").font(.system(size: 8))
                    Spacer()
                    Button { UIPasteboard.general.string = log.message } label: { Image(systemName: "doc.on.doc").font(.caption2) }.buttonStyle(.bordered).controlSize(.mini)
                }.foregroundStyle(.tertiary).padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

private struct DetailMetricPill: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).foregroundStyle(color)
            Text(label).font(.caption2.bold()).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
