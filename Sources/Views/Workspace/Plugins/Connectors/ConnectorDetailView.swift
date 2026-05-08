import SwiftUI

struct ConnectorDetailView<T: BaseConnector>: View {
    @ObservedObject var connector: T
    @State private var showingAuth = false
    @State private var isTesting = false
    @State private var isSyncing = false
    @State private var showingDisconnectAlert = false
    @State private var expandedLogID: UUID?
    @State private var logFilter: LogFilterType = .all
    @State private var showingClearLogsAlert = false

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
            // MARK: - Status Overview
            Section {
                HStack(spacing: 16) {
                    detailStat(label: "Status", value: connector.status.rawValue.capitalized,
                              color: connector.status == .connected ? .green : .red)
                    detailStat(label: "Events", value: "\(connector.activityLog.count)", color: .blue)
                    detailStat(label: "Type", value: connector.type.rawValue.capitalized, color: .purple)
                }
            }

            // MARK: - Connection Details
            Section {
                HStack {
                    Text("Connection Status")
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(connector.status == .connected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(connector.status.rawValue.capitalized)
                            .foregroundStyle(connector.status == .connected ? .green : .red)
                            .bold()
                    }
                }

                HStack {
                    Text("Connector Type")
                    Spacer()
                    Text(connector.type.rawValue.capitalized)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Auth Fields")
                    Spacer()
                    Text("\(connector.authFields.count)")
                        .foregroundColor(.secondary)
                }

                if let lastEvent = connector.activityLog.first {
                    HStack {
                        Text("Last Activity")
                        Spacer()
                        Text(lastEvent.timestamp.formatted(.relative(presentation: .numeric)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let firstEvent = connector.activityLog.last {
                    HStack {
                        Text("First Activity")
                        Spacer()
                        Text(firstEvent.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Connection Details")
            }

            // MARK: - Actions
            Section {
                Button {
                    isTesting = true
                    Task {
                        try? await connector.testConnection()
                        await MainActor.run { isTesting = false }
                    }
                } label: {
                    HStack {
                        Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                        Spacer()
                        if isTesting { ProgressView().scaleEffect(0.7) }
                    }
                }
                .disabled(isTesting)

                Button {
                    isSyncing = true
                    Task {
                        try? await connector.sync()
                        await MainActor.run { isSyncing = false }
                    }
                } label: {
                    HStack {
                        Label("Force Sync", systemImage: "arrow.clockwise")
                        Spacer()
                        if isSyncing { ProgressView().scaleEffect(0.7) }
                    }
                }
                .disabled(isSyncing)

                Button {
                    showingAuth = true
                } label: {
                    Label("Configure Auth", systemImage: "key")
                }

                Button(role: .destructive) {
                    showingDisconnectAlert = true
                } label: {
                    Label("Disconnect", systemImage: "xmark.circle")
                }
            } header: {
                Text("Actions")
            }

            // MARK: - Activity Log
            Section {
                Picker("Filter", selection: $logFilter) {
                    ForEach(LogFilterType.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                if filteredActivityLog.isEmpty {
                    Text("No Activity Recorded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    ForEach(filteredActivityLog) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.level.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(color(for: event.level).opacity(0.15))
                                    .foregroundStyle(color(for: event.level))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Spacer()

                                Text(event.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Text(event.message)
                                .font(.subheadline)

                            if expandedLogID == event.id {
                                Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                expandedLogID = expandedLogID == event.id ? nil : event.id
                            }
                        }
                    }
                }
            } header: {
                Text("Activity Log (\(filteredActivityLog.count))")
            }
        }
        .navigationTitle(connector.name)
        .sheet(isPresented: $showingAuth) {
            ConnectorAuthView(connector: connector)
        }
        .alert("Disconnect \(connector.name)?", isPresented: $showingDisconnectAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                connector.disconnect()
            }
        } message: {
            Text("This will disconnect the connector and stop all sync operations.")
        }
    }

    // MARK: - Helpers

    private func detailStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func color(for level: LogLevel) -> Color {
        switch level {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        case .debug: return .gray
        }
    }
}
