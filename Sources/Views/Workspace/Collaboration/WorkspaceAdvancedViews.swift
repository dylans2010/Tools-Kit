import SwiftUI
import Workspace

// MARK: - Global Search View

struct WorkspaceGlobalSearchView: View {
    @StateObject private var searchService = GlobalSearchService.shared
    @State private var query = ""
    @State private var selectedTypes: Set<String> = []
    @FocusState private var isFocused: Bool

    private let typeFilters = ["Space", "Task", "Decision"] + ContentGraphService.NodeType.allCases.map { $0.rawValue }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search workspace…", text: $query)
                    .focused($isFocused)
                    .onSubmit { searchService.search(query: query, types: selectedTypes) }
                    .onChange(of: query) { _, new in
                        if new.count > 1 { searchService.search(query: new, types: selectedTypes) }
                        else if new.isEmpty { searchService.search(query: "") }
                    }
                if !query.isEmpty {
                    Button(action: { query = ""; searchService.search(query: "") }) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.top)

            // Type filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All Types", isSelected: selectedTypes.isEmpty) {
                        selectedTypes = []
                        searchService.search(query: query)
                    }
                    ForEach(typeFilters, id: \.self) { type in
                        FilterChip(title: type, isSelected: selectedTypes.contains(type)) {
                            if selectedTypes.contains(type) { selectedTypes.remove(type) }
                            else { selectedTypes.insert(type) }
                            searchService.search(query: query, types: selectedTypes)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            if searchService.isSearching {
                ProgressView("Searching…").padding()
            } else if query.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass").font(.system(size: 40)).foregroundStyle(.tertiary)
                    Text("Search across spaces, tasks, decisions, and graph nodes.")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if searchService.results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(searchService.results) { result in
                    SearchResultRow(result: result)
                }
            }
        }
        .navigationTitle("Global Search")
        .onAppear { isFocused = true }
    }
}

struct SearchResultRow: View {
    let result: GlobalSearchService.SearchResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.icon)
                .font(.title3)
                .foregroundStyle(colorFor(result.type))
                .frame(width: 36, height: 36)
                .background(colorFor(result.type).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(result.title).font(.subheadline).bold()
                Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Text(result.type).font(.caption2).foregroundStyle(.tertiary)
        }
    }

    private func colorFor(_ type: String) -> Color {
        switch type {
        case "Space": return .blue
        case "Task": return .green
        case "Decision": return .purple
        case "Note": return .orange
        default: return .gray
        }
    }
}

// MARK: - Workspace Tools Panel

struct WorkspaceToolsPanelView: View {
    @StateObject private var analytics = WorkspaceAnalyticsTool()
    @StateObject private var integrity = DataIntegrityService.shared
    @StateObject private var notif = WorkspaceNotificationService.shared
    @State private var generatedReport = ""
    @State private var showingReport = false

    private let spaceID: UUID?

    init(spaceID: UUID? = nil) {
        self.spaceID = spaceID
    }

    var body: some View {
        List {
            Section("Analytics") {
                Button {
                    if let id = spaceID { analytics.fetchAnalytics(for: id) }
                } label: {
                    Label("Refresh Analytics", systemImage: "chart.bar.xaxis")
                }
                if let id = spaceID, let _ = CollaborationManager.shared.spaces.first(where: { $0.id == id }) {
                    LabeledContent("Total Commits", value: "\(analytics.totalCommits)")
                    LabeledContent("Active Users", value: "\(analytics.activeUsersCount)")
                }
            }

            Section("Integrity") {
                Button {
                    integrity.runScan()
                } label: {
                    Label("Run Integrity Scan", systemImage: "stethoscope")
                        .foregroundStyle(.blue)
                }

                if integrity.isScanning {
                    HStack { ProgressView(); Text("Scanning…").font(.caption) }
                }

                ForEach(integrity.issues) { issue in
                    IntegrityIssueRow(issue: issue)
                }
            }

            Section("Reports") {
                Button {
                    generatedReport = generateFullReport()
                    showingReport = true
                } label: {
                    Label("Generate Full Report", systemImage: "doc.text.fill")
                }

                Button {
                    let emptyTaskIDs = ProjectExecutionBoardTool.shared.tasks.filter { $0.title.isEmpty }.map { $0.id }
                    ProjectExecutionBoardTool.shared.removeTasks(ids: emptyTaskIDs)
                    CollaborationManager.shared.cleanOrphanedTaskRefs()
                    notif.post(title: "Workspace Cleaned", body: "Removed \(emptyTaskIDs.count) empty task(s) and cleaned orphaned references.", category: .update)
                } label: {
                    Label("Clean Unused Data", systemImage: "trash")
                        .foregroundStyle(.orange)
                }
            }

            Section("Notifications (\(notif.unreadCount) unread)") {
                ForEach(notif.notifications.prefix(5)) { n in
                    NotificationRow(notification: n)
                }
                if notif.notifications.count > 5 {
                    Text("+ \(notif.notifications.count - 5) more notifications").font(.caption).foregroundStyle(.secondary)
                }
                if !notif.notifications.isEmpty {
                    Button("Mark All Read") { notif.markAllRead() }
                        .foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle("Workspace Tools")
        .sheet(isPresented: $showingReport) {
            ReportDetailView(report: generatedReport)
        }
    }

    private func generateFullReport() -> String {
        let spaces = CollaborationManager.shared.spaces
        let tasks = ProjectExecutionBoardTool.shared.tasks
        let automations = WorkspaceAutomationEngine.shared.automations
        let nodes = ContentGraphService.shared.nodes

        var report = "# Workspace Report\n"
        report += "Generated: \(Date().formatted(date: .complete, time: .shortened))\n\n"
        report += "## Spaces (\(spaces.count))\n"
        for s in spaces {
            report += "• \(s.name) — \(s.activityFeed.count) activity events\n"
        }
        report += "\n## Tasks (\(tasks.count))\n"
        let done = tasks.filter { $0.status == .done }.count
        report += "• Done: \(done) / \(tasks.count)\n"
        report += "• Pending: \(tasks.count - done)\n"
        report += "\n## Automations (\(automations.count))\n"
        for a in automations {
            report += "• \(a.name) — \(a.executionCount) runs (\(a.isEnabled ? "enabled" : "disabled"))\n"
        }
        report += "\n## Content Graph\n"
        report += "• Nodes: \(nodes.count)\n"
        report += "• Edges: \(ContentGraphService.shared.edges.count)\n"
        return report
    }
}

struct IntegrityIssueRow: View {
    let issue: DataIntegrityService.IntegrityIssue
    @StateObject private var service = DataIntegrityService.shared

    var body: some View {
        HStack {
            Image(systemName: issue.severity == .error ? "xmark.circle.fill" : issue.severity == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundStyle(issue.severity == .error ? .red : issue.severity == .warning ? .orange : .blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.description).font(.caption)
                if issue.isFixed { Text("✓ Fixed").font(.caption2).foregroundStyle(.green) }
            }
            Spacer()
            if issue.autoFixable && !issue.isFixed {
                Button("Fix") { service.autoFix(issue: issue) }
                    .font(.caption.bold())
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
        }
    }
}

struct NotificationRow: View {
    let notification: WorkspaceNotificationService.WorkspaceNotification
    @StateObject private var service = WorkspaceNotificationService.shared

    var body: some View {
        HStack {
            Circle()
                .fill(notification.isRead ? Color.clear : Color.blue)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title).font(.caption.bold())
                Text(notification.body).font(.caption2).foregroundStyle(.secondary)
                Text(notification.timestamp, style: .relative).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            if !notification.isRead {
                Button(action: { service.markRead(id: notification.id) }) {
                    Image(systemName: "checkmark").font(.caption)
                }
            }
        }
    }
}

struct ReportDetailView: View {
    let report: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(report)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Workspace Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
