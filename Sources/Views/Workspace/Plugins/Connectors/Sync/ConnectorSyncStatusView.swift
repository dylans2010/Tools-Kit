import SwiftUI

struct ConnectorSyncStatusView: View {
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @State private var syncJobs: [SyncJob] = []
    @State private var isRefreshing = false
    @State private var showingScheduler = false
    @State private var showingConflicts = false
    @State private var autoSyncEnabled = false
    @State private var syncInterval: SyncInterval = .minutes15
    @State private var conflicts: [SyncConflict] = []
    @State private var syncHistory: [SyncHistoryEntry] = []
    @State private var selectedJobID: UUID?
    @State private var showingJobDetail = false
    @State private var batchSyncInProgress = false
    @State private var syncBandwidthBytes: Int = 0
    @State private var showingRetryOptions = false
    @State private var retryStrategy: RetryStrategy = .exponential
    @State private var maxRetryAttempts: Int = 3

    var body: some View {
        List {
            overviewSection
            scheduleSection
            activeSection
            conflictsSection
            historySection
            retrySection
            bandwidthSection
            actionsSection
        }
        .navigationTitle("Sync Status")
        .refreshable { await refreshSyncState() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingScheduler = true } label: { Label("Schedule Sync", systemImage: "calendar.badge.clock") }
                    Button { showingRetryOptions = true } label: { Label("Retry Settings", systemImage: "arrow.clockwise.circle") }
                    Divider()
                    Button(role: .destructive) { clearHistory() } label: { Label("Clear History", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .task { await refreshSyncState() }
        .sheet(isPresented: $showingScheduler) {
            NavigationStack { syncSchedulerSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingConflicts) {
            NavigationStack { conflictResolutionSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingRetryOptions) {
            NavigationStack { retrySettingsSheet }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedJobID) { jobID in
            if let job = syncJobs.first(where: { $0.id == jobID }) {
                NavigationStack { syncJobDetailSheet(job) }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        Section("Sync Overview") {
            HStack(spacing: 16) {
                syncStatCard(title: "Active", value: "\(syncJobs.filter { $0.status == .running }.count)", color: .blue)
                syncStatCard(title: "Completed", value: "\(syncJobs.filter { $0.status == .completed }.count)", color: .green)
                syncStatCard(title: "Failed", value: "\(syncJobs.filter { $0.status == .failed }.count)", color: .red)
                syncStatCard(title: "Pending", value: "\(syncJobs.filter { $0.status == .pending }.count)", color: .orange)
            }
            LabeledContent("Total Records Synced") {
                Text("\(syncJobs.reduce(0) { $0 + $1.recordsSynced })")
                    .font(.body.monospacedDigit().bold())
            }
            LabeledContent("Last Full Sync") {
                if let lastCompleted = syncJobs.filter({ $0.status == .completed }).sorted(by: { $0.lastUpdated > $1.lastUpdated }).first {
                    Text(lastCompleted.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                } else {
                    Text("Never").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        Section("Auto-Sync") {
            Toggle("Enable Scheduled Sync", isOn: $autoSyncEnabled)
            if autoSyncEnabled {
                Picker("Interval", selection: $syncInterval) {
                    ForEach(SyncInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                LabeledContent("Next Sync") {
                    Text(Date().addingTimeInterval(syncInterval.seconds).formatted(date: .omitted, time: .shortened))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    // MARK: - Active Syncs Section

    private var activeSection: some View {
        Section("Active Syncs") {
            let active = syncJobs.filter { $0.status == .running }
            if active.isEmpty {
                Text("No active sync operations")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(active) { job in
                    Button { selectedJobID = job.id; showingJobDetail = true } label: {
                        syncJobRow(job)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { cancelSync(job) } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                    }
                }
            }

            ForEach(syncJobs.filter { $0.status == .pending }) { job in
                syncJobRow(job)
            }
        }
    }

    // MARK: - Conflicts Section

    private var conflictsSection: some View {
        Section("Sync Conflicts") {
            if conflicts.isEmpty {
                Label("No conflicts detected", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                ForEach(conflicts) { conflict in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(conflict.fieldName)
                                .font(.subheadline.bold())
                            Text("Local: \(conflict.localValue) vs Remote: \(conflict.remoteValue)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(conflict.connectorName)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Button("Resolve All Conflicts") { showingConflicts = true }
                    .font(.caption)
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        Section("Sync History") {
            if syncHistory.isEmpty {
                Text("No sync history available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(syncHistory.prefix(10)) { entry in
                    HStack {
                        Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(entry.success ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.connectorName).font(.subheadline)
                            Text("\(entry.recordsSynced) records in \(String(format: "%.1f", entry.duration))s")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Retry Section

    private var retrySection: some View {
        Section("Retry Configuration") {
            Picker("Strategy", selection: $retryStrategy) {
                ForEach(RetryStrategy.allCases, id: \.self) { strategy in
                    Text(strategy.rawValue.capitalized).tag(strategy)
                }
            }
            Stepper("Max Attempts: \(maxRetryAttempts)", value: $maxRetryAttempts, in: 1...10)
        }
    }

    // MARK: - Bandwidth Section

    private var bandwidthSection: some View {
        Section("Bandwidth Usage") {
            LabeledContent("Data Transferred") {
                Text(formatBytes(syncBandwidthBytes))
                    .font(.body.monospacedDigit())
            }
            if syncBandwidthBytes > 0 {
                let avgPerSync = syncJobs.isEmpty ? syncBandwidthBytes : syncBandwidthBytes / max(syncJobs.count, 1)
                LabeledContent("Avg Per Sync") {
                    Text(formatBytes(avgPerSync))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section("Actions") {
            Button {
                Task { await syncAllConnectors() }
            } label: {
                Label(batchSyncInProgress ? "Syncing All..." : "Sync All Connectors", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(batchSyncInProgress)

            Button { refresh() } label: {
                Label(isRefreshing ? "Refreshing..." : "Refresh Status", systemImage: "arrow.clockwise")
            }
            .disabled(isRefreshing)

            Button {
                retryFailedSyncs()
            } label: {
                Label("Retry Failed Syncs", systemImage: "arrow.clockwise.circle")
            }
            .disabled(syncJobs.filter({ $0.status == .failed }).isEmpty)
        }
    }

    // MARK: - Sheets

    private var syncSchedulerSheet: some View {
        Form {
            Section("Schedule Configuration") {
                Picker("Frequency", selection: $syncInterval) {
                    ForEach(SyncInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                Toggle("Enable Auto-Sync", isOn: $autoSyncEnabled)
            }
            Section("Connector Selection") {
                ForEach(connectorManager.connectors, id: \.id) { connector in
                    HStack {
                        Text(connector.name).font(.subheadline)
                        Spacer()
                        Image(systemName: connector.isConnected ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(connector.isConnected ? .green : .secondary)
                    }
                }
            }
        }
        .navigationTitle("Sync Scheduler")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var conflictResolutionSheet: some View {
        List {
            ForEach(conflicts) { conflict in
                VStack(alignment: .leading, spacing: 8) {
                    Text(conflict.fieldName).font(.subheadline.bold())
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Local").font(.caption2.bold()).foregroundStyle(.blue)
                            Text(conflict.localValue).font(.caption.monospaced())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Remote").font(.caption2.bold()).foregroundStyle(.orange)
                            Text(conflict.remoteValue).font(.caption.monospaced())
                        }
                    }
                    HStack {
                        Button("Keep Local") { resolveConflict(conflict, useLocal: true) }
                            .buttonStyle(.bordered).controlSize(.small)
                        Button("Keep Remote") { resolveConflict(conflict, useLocal: false) }
                            .buttonStyle(.bordered).controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Resolve Conflicts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var retrySettingsSheet: some View {
        Form {
            Section("Retry Strategy") {
                Picker("Strategy", selection: $retryStrategy) {
                    ForEach(RetryStrategy.allCases, id: \.self) { s in
                        Text(s.rawValue.capitalized).tag(s)
                    }
                }
                Stepper("Max Attempts: \(maxRetryAttempts)", value: $maxRetryAttempts, in: 1...10)
            }
            Section("Strategy Details") {
                switch retryStrategy {
                case .linear:
                    Text("Retries at fixed intervals (2s between each attempt)")
                        .font(.caption).foregroundStyle(.secondary)
                case .exponential:
                    Text("Exponential backoff (2s, 4s, 8s, ...)")
                        .font(.caption).foregroundStyle(.secondary)
                case .immediate:
                    Text("Retries immediately without delay")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Retry Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func syncJobDetailSheet(_ job: SyncJob) -> some View {
        Form {
            Section("Job Details") {
                LabeledContent("Connector", value: job.connectorName)
                LabeledContent("Status", value: job.status.rawValue.capitalized)
                LabeledContent("Records Synced", value: "\(job.recordsSynced)")
                LabeledContent("Last Updated", value: job.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                if job.status == .running {
                    LabeledContent("Progress") {
                        ProgressView(value: job.progress)
                            .frame(width: 100)
                    }
                }
            }
            if let error = job.errorMessage {
                Section("Error") {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Sync Job")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func syncJobRow(_ job: SyncJob) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: job.status.icon)
                    .foregroundStyle(job.status.color)
                Text(job.connectorName)
                    .font(.headline)
                Spacer()
                Text(job.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(job.status.color.opacity(0.15))
                    .clipShape(Capsule())
            }
            if job.status == .running {
                ProgressView(value: job.progress)
                    .tint(.blue)
                Text("\(Int(job.progress * 100))% complete")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("\(job.recordsSynced) records")
                    .font(.caption)
                if let direction = job.direction {
                    Text("(\(direction.rawValue))")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                Spacer()
                Text(job.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func syncStatCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func refresh() {
        isRefreshing = true
        Task {
            await refreshSyncState()
            await MainActor.run { isRefreshing = false }
        }
    }

    private func refreshSyncState() async {
        var jobs: [SyncJob] = []
        for connector in connectorManager.connectors {
            let status: SyncStatus = connector.isConnected ? .completed : .pending
            jobs.append(SyncJob(
                connectorName: connector.name,
                status: status,
                progress: status == .completed ? 1.0 : 0.0,
                recordsSynced: connector.activityLog.count,
                lastUpdated: connector.activityLog.first?.timestamp ?? Date(),
                direction: .bidirectional,
                errorMessage: nil
            ))
        }
        syncJobs = jobs
        syncBandwidthBytes = jobs.reduce(0) { $0 + $1.recordsSynced * 256 }
    }

    private func syncAllConnectors() async {
        batchSyncInProgress = true
        try? await connectorManager.syncAll()
        await refreshSyncState()
        batchSyncInProgress = false
    }

    private func cancelSync(_ job: SyncJob) {
        syncJobs.removeAll { $0.id == job.id }
    }

    private func retryFailedSyncs() {
        for i in syncJobs.indices where syncJobs[i].status == .failed {
            syncJobs[i] = SyncJob(
                connectorName: syncJobs[i].connectorName,
                status: .pending,
                progress: 0,
                recordsSynced: 0,
                lastUpdated: Date(),
                direction: syncJobs[i].direction,
                errorMessage: nil
            )
        }
    }

    private func resolveConflict(_ conflict: SyncConflict, useLocal: Bool) {
        conflicts.removeAll { $0.id == conflict.id }
    }

    private func clearHistory() {
        syncHistory = []
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}

// MARK: - Extension for UUID Identifiable sheet binding

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

// MARK: - Private Models

private struct SyncJob: Identifiable {
    let id = UUID()
    let connectorName: String
    let status: SyncStatus
    let progress: Double
    let recordsSynced: Int
    let lastUpdated: Date
    let direction: SyncDirection?
    let errorMessage: String?
}

private enum SyncStatus: String {
    case running, completed, failed, pending

    var icon: String {
        switch self {
        case .running: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .pending: return "clock"
        }
    }

    var color: Color {
        switch self {
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .pending: return .orange
        }
    }
}

private enum SyncDirection: String {
    case push = "Push"
    case pull = "Pull"
    case bidirectional = "Bidirectional"
}

private enum SyncInterval: String, CaseIterable {
    case minutes5 = "5min"
    case minutes15 = "15min"
    case minutes30 = "30min"
    case hourly = "1hr"
    case daily = "24hr"

    var displayName: String {
        switch self {
        case .minutes5: return "Every 5 Minutes"
        case .minutes15: return "Every 15 Minutes"
        case .minutes30: return "Every 30 Minutes"
        case .hourly: return "Every Hour"
        case .daily: return "Every Day"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .minutes5: return 300
        case .minutes15: return 900
        case .minutes30: return 1800
        case .hourly: return 3600
        case .daily: return 86400
        }
    }
}

private enum RetryStrategy: String, CaseIterable {
    case immediate, linear, exponential
}

private struct SyncConflict: Identifiable {
    let id = UUID()
    let connectorName: String
    let fieldName: String
    let localValue: String
    let remoteValue: String
}

private struct SyncHistoryEntry: Identifiable {
    let id = UUID()
    let connectorName: String
    let success: Bool
    let recordsSynced: Int
    let duration: Double
    let timestamp: Date
}
