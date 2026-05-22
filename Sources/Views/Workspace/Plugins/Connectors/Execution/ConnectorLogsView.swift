

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
    @State private var showingLogAnalysis = false
    @State private var showingExportOptions = false
    @State private var bookmarkedLogs: Set<UUID> = []
    @State private var showingBookmarks = false
    @State private var logGrouping: LogGrouping = .none
    @State private var showingPatternDetection = false
    @State private var detectedPatterns: [LogPattern] = []

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
                    Picker("Group", selection: $logGrouping) {
                        ForEach(LogGrouping.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.menu).controlSize(.small)
                    Spacer()
                    Toggle(isOn: $autoRefreshEnabled) { Label("Live", systemImage: "arrow.clockwise") }.toggleStyle(.button).controlSize(.mini)
                }
            }
            .padding().background(Color(.secondarySystemGroupedBackground))

            List {
                if filteredLogs.isEmpty {
                    ContentUnavailableView("No Logs Found", systemImage: "doc.text.magnifyingglass", description: Text("No entries match your current search or filter criteria."))
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredLogs) { log in
                        ConnectorLogLine(log: log, isExpanded: expandedLogID == log.id, isBookmarked: bookmarkedLogs.contains(log.id)) {
                            withAnimation { expandedLogID = expandedLogID == log.id ? nil : log.id }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                if bookmarkedLogs.contains(log.id) {
                                    bookmarkedLogs.remove(log.id)
                                } else {
                                    bookmarkedLogs.insert(log.id)
                                }
                            } label: {
                                Label(bookmarkedLogs.contains(log.id) ? "Unbookmark" : "Bookmark", systemImage: "bookmark")
                            }
                            .tint(.blue)
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
                    Button { showingLogAnalysis = true } label: { Label("Log Analysis", systemImage: "chart.bar") }
                    Button { showingBookmarks = true } label: { Label("Bookmarks (\(bookmarkedLogs.count))", systemImage: "bookmark") }
                    Button { runPatternDetection(); showingPatternDetection = true } label: { Label("Pattern Detection", systemImage: "wand.and.stars") }
                    Divider()
                    Button { showingExportOptions = true } label: { Label("Export Options", systemImage: "square.and.arrow.up") }
                    Button(role: .destructive) { showingClearAlert = true } label: { Label("Clear Logs", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .alert("Clear Logs?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { if let id = connectorID { manager.clearLogs(for: id) } else { manager.clearAllLogs() } }
        } message: { Text("This will permanently remove all recorded events for this context.") }
        .sheet(isPresented: $showingLogAnalysis) {
            NavigationStack { logAnalysisSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingBookmarks) {
            NavigationStack { bookmarksSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExportOptions) {
            NavigationStack { exportOptionsSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPatternDetection) {
            NavigationStack { patternDetectionSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Log Analysis Sheet

    private var logAnalysisSheet: some View {
        List {
            Section("Log Distribution") {
                let allLogs = connectorID == nil ? manager.logs : manager.logs.filter { $0.connectorID == connectorID }
                let total = allLogs.count
                let errorCount = allLogs.filter { $0.type == .error }.count
                let warnCount = allLogs.filter { $0.type == .warning }.count
                let infoCount = allLogs.filter { $0.type == .info }.count
                let perfCount = allLogs.filter { $0.type == .performance }.count

                LabeledContent("Total Logs", value: "\(total)")
                LabeledContent("Errors") { Text("\(errorCount)").foregroundStyle(.red) }
                LabeledContent("Warnings") { Text("\(warnCount)").foregroundStyle(.orange) }
                LabeledContent("Info") { Text("\(infoCount)").foregroundStyle(.blue) }
                LabeledContent("Performance") { Text("\(perfCount)").foregroundStyle(.purple) }
                if total > 0 {
                    LabeledContent("Error Rate") {
                        Text("\(Int(Double(errorCount) / Double(total) * 100))%")
                            .foregroundStyle(errorCount > 0 ? .red : .green)
                    }
                }
            }
            Section("Time Analysis") {
                let logs = filteredLogs
                if let first = logs.last, let last = logs.first {
                    LabeledContent("Oldest", value: first.timestamp.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Newest", value: last.timestamp.formatted(date: .abbreviated, time: .shortened))
                    let span = last.timestamp.timeIntervalSince(first.timestamp)
                    LabeledContent("Time Span", value: "\(Int(span / 3600))h \(Int(span.truncatingRemainder(dividingBy: 3600) / 60))m")
                    if span > 0 {
                        LabeledContent("Avg Rate", value: "\(Int(Double(logs.count) / (span / 60)))/min")
                    }
                }
            }
        }
        .navigationTitle("Log Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Bookmarks Sheet

    private var bookmarksSheet: some View {
        List {
            if bookmarkedLogs.isEmpty {
                ContentUnavailableView("No Bookmarks", systemImage: "bookmark.slash", description: Text("Swipe right on log entries to bookmark them."))
            } else {
                let bookmarked = filteredLogs.filter { bookmarkedLogs.contains($0.id) }
                ForEach(bookmarked) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.type.rawValue.uppercased()).font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(log.type.color.opacity(0.1), in: Capsule()).foregroundStyle(log.type.color)
                            Spacer()
                            Text(log.timestamp.formatted(date: .omitted, time: .standard)).font(.caption2).foregroundStyle(.secondary)
                        }
                        Text(log.message).font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Bookmarked Logs")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Export Options Sheet

    private var exportOptionsSheet: some View {
        Form {
            Section("Export Format") {
                Button("Copy as Text") { exportLogs(format: .text) }
                Button("Copy as JSON") { exportLogs(format: .json) }
                Button("Copy as CSV") { exportLogs(format: .csv) }
            }
            Section("Scope") {
                LabeledContent("Logs to Export", value: "\(filteredLogs.count)")
                LabeledContent("Filter Active", value: filter.rawValue)
                LabeledContent("Date Range", value: selectedDateRange.rawValue)
            }
        }
        .navigationTitle("Export Options")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pattern Detection Sheet

    private var patternDetectionSheet: some View {
        List {
            if detectedPatterns.isEmpty {
                ContentUnavailableView("No Patterns", systemImage: "wand.and.stars", description: Text("No recurring patterns detected in logs."))
            } else {
                ForEach(detectedPatterns) { pattern in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(pattern.pattern).font(.subheadline.bold())
                            Spacer()
                            Text("\(pattern.count)x").font(.caption.monospacedDigit()).foregroundStyle(.blue)
                        }
                        Text("First: \(pattern.firstSeen.formatted(date: .omitted, time: .shortened)) — Last: \(pattern.lastSeen.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Pattern Detection")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func exportLogs(format: LogExportFormat = .text) {
        let logs = filteredLogs
        let text: String
        switch format {
        case .text:
            text = logs.map { "[\($0.type.rawValue.uppercased())] \($0.timestamp.formatted())\n\($0.message)\($0.details != nil ? "\n\($0.details!)" : "")" }.joined(separator: "\n---\n")
        case .json:
            let entries = logs.map { "{\"type\":\"\($0.type.rawValue)\",\"message\":\"\($0.message)\",\"timestamp\":\"\($0.timestamp.formatted())\"}" }
            text = "[\(entries.joined(separator: ","))]"
        case .csv:
            let header = "type,message,timestamp"
            let rows = logs.map { "\($0.type.rawValue),\"\($0.message)\",\($0.timestamp.formatted())" }
            text = ([header] + rows).joined(separator: "\n")
        }
        UIPasteboard.general.string = text
    }

    private func runPatternDetection() {
        var messageFrequency: [String: (count: Int, first: Date, last: Date)] = [:]
        for log in filteredLogs {
            let key = String(log.message.prefix(60))
            if var existing = messageFrequency[key] {
                existing.count += 1
                if log.timestamp < existing.first { existing.first = log.timestamp }
                if log.timestamp > existing.last { existing.last = log.timestamp }
                messageFrequency[key] = existing
            } else {
                messageFrequency[key] = (count: 1, first: log.timestamp, last: log.timestamp)
            }
        }
        detectedPatterns = messageFrequency
            .filter { $0.value.count >= 2 }
            .map { LogPattern(pattern: $0.key, count: $0.value.count, firstSeen: $0.value.first, lastSeen: $0.value.last) }
            .sorted { $0.count > $1.count }
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
        .padding(.vertical, 12).background(Color(.systemGroupedBackground))
    }
}

private struct ConnectorLogLine: View {
    let log: ConnectorLog
    let isExpanded: Bool
    var isBookmarked: Bool = false
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.type.rawValue.uppercased()).font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(log.type.color.opacity(0.1), in: Capsule()).foregroundStyle(log.type.color)
                if isBookmarked {
                    Image(systemName: "bookmark.fill").font(.system(size: 8)).foregroundStyle(.blue)
                }
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

// MARK: - New Log Models

private enum LogGrouping: String, CaseIterable {
    case none = "None"
    case byType = "By Type"
    case byConnector = "By Connector"
    case byHour = "By Hour"
}

private enum LogExportFormat {
    case text, json, csv
}

private struct LogPattern: Identifiable {
    let id = UUID()
    let pattern: String
    let count: Int
    let firstSeen: Date
    let lastSeen: Date
}
