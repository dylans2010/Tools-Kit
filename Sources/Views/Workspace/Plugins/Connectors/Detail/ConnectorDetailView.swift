/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Modernized the status header using a centered detailStat group with SDKStatPill-like metrics.
 - Replaced manual connection details with native LabeledContent rows and semantic status badges.
 - Modernized the Action section with standardized Label components and progress indicators.
 - Standardized the Activity Log with a segmented filter and improved row hierarchy.
 - strictly preserved all BaseConnector testing, syncing, and log filtering logic.
 - Added expandable log entries for detailed timestamp viewing.
 - Applied modern sheet detents for authentication configuration.
 */

import SwiftUI

struct ConnectorDetailView<T: BaseConnector>: View {
    @ObservedObject var connector: T
    @State private var showingAuth = false
    @State private var isTesting = false
    @State private var isSyncing = false
    @State private var showingDisconnectAlert = false
    @State private var expandedLogID: UUID?
    @State private var logFilter: LogFilterType = .all

    enum LogFilterType: String, CaseIterable {
        case all = "All"
        case errors = "Errors"
        case warnings = "Warnings"
        case info = "Info"
    }

    var filteredActivityLog: [ConnectorEvent] {
        let logs = Array(connector.activityLog.prefix(50))
        switch logFilter {
        case .all: return logs
        case .errors: return logs.filter { $0.level == .error }
        case .warnings: return logs.filter { $0.level == .warning }
        case .info: return logs.filter { $0.level == .info }
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 0) {
                    DetailMetricPill(label: "Status", value: connector.status.rawValue.capitalized, color: connector.status == .connected ? .sdkSuccess : .red)
                    DetailMetricPill(label: "Events", value: "\(connector.activityLog.count)", color: .blue)
                    DetailMetricPill(label: "Type", value: connector.type.rawValue.capitalized, color: .purple)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section("Connection Profile") {
                LabeledContent("Status") {
                    SDKStatusPill(
                        connector.status.rawValue.uppercased(),
                        systemImage: connector.status == .connected ? "checkmark.circle.fill" : "xmark.circle.fill",
                        color: connector.status == .connected ? .sdkSuccess : .red
                    )
                }
                LabeledContent("Platform Type", value: connector.type.rawValue.capitalized)
                LabeledContent("Auth Fields", value: "\(connector.authFields.count)")

                if let lastEvent = connector.activityLog.first {
                    LabeledContent("Last Active") {
                        Text(lastEvent.timestamp.formatted(.relative(presentation: .numeric)))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Maintenance") {
                Button {
                    isTesting = true
                    Task { try? await connector.testConnection(); isTesting = false }
                } label: {
                    HStack {
                        Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                        Spacer()
                        if isTesting { ProgressView().controlSize(.small) }
                    }
                }
                .disabled(isTesting)

                Button {
                    isSyncing = true
                    Task { try? await connector.sync(); isSyncing = false }
                } label: {
                    HStack {
                        Label("Force Data Sync", systemImage: "arrow.clockwise")
                        Spacer()
                        if isSyncing { ProgressView().controlSize(.small) }
                    }
                }
                .disabled(isSyncing)

                Button { showingAuth = true } label: {
                    Label("Update Credentials", systemImage: "key.fill")
                }

                Button(role: .destructive) { showingDisconnectAlert = true } label: {
                    Label("Disconnect Connector", systemImage: "link.badge.plus")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Picker("Filter", selection: $logFilter) {
                    ForEach(LogFilterType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            } header: { Text("Activity Monitor") }

            Section {
                if filteredActivityLog.isEmpty {
                    ContentUnavailableView("No Activity", systemImage: "waveform.path.ecg", description: Text("No events recorded for the selected filter."))
                } else {
                    ForEach(filteredActivityLog) { event in
                        ConnectorLogEntryRow(event: event, isExpanded: expandedLogID == event.id)
                            .contentShape(Rectangle())
                            .onTapGesture { withAnimation { expandedLogID = expandedLogID == event.id ? nil : event.id } }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(connector.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAuth) {
            ConnectorAuthView(connector: connector)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .alert("Disconnect \(connector.name)?", isPresented: $showingDisconnectAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) { connector.disconnect() }
        } message: {
            Text("This will invalidate the current session and stop all automated sync operations.")
        }
    }
}

// MARK: - Private Subviews

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

private struct ConnectorLogEntryRow: View {
    let event: ConnectorEvent
    let isExpanded: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(event.level.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(color(for: event.level).opacity(0.1), in: Capsule())
                    .foregroundStyle(color(for: event.level))
                Spacer()
                Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
            Text(event.message).font(.subheadline)
            if isExpanded {
                Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                    .font(.system(size: 9)).foregroundStyle(.tertiary).padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
    private func color(for level: LogLevel) -> Color {
        switch level {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        case .debug: return .secondary
        }
    }
}
