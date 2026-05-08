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
        case all = "All", errors = "Errors", warnings = "Warnings", info = "Info"
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
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                SDKModernCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(connector.name).font(.title3.bold())
                                Text(connector.type.rawValue.capitalized).sdkSubtext()
                            }
                            Spacer()
                            SDKStatusPill(
                                status: connector.status == .connected ? .success : .error,
                                text: connector.status.rawValue.uppercased()
                            )
                        }

                        Divider()

                        HStack(spacing: 20) {
                            statItem(label: "Fields", value: "\(connector.authFields.count)")
                            statItem(label: "Events", value: "\(connector.activityLog.count)")
                            if let last = connector.activityLog.first {
                                statItem(label: "Last Seen", value: last.timestamp.formatted(.relative(presentation: .numeric)))
                            }
                        }
                    }
                }

                // MARK: - Actions
                SDKSectionHeader(title: "Operations", subtext: "Live connection management.")
                SDKModernCard {
                    VStack(spacing: 12) {
                        actionButton(title: "Test Connection", icon: "antenna.radiowaves.left.and.right", loading: isTesting) {
                            isTesting = true
                            Task { try? await connector.testConnection(); isTesting = false }
                        }

                        actionButton(title: "Force Sync", icon: "arrow.clockwise", loading: isSyncing) {
                            isSyncing = true
                            Task { try? await connector.sync(); isSyncing = false }
                        }

                        Button { showingAuth = true } label: {
                            managementRow(title: "Configure Auth", icon: "key", subtitle: "Credentials and fields")
                        }

                        Divider().padding(.vertical, 4)

                        Button(role: .destructive) { showingDisconnectAlert = true } label: {
                            Label("Disconnect", systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity).font(.subheadline.bold())
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // MARK: - Activity Log
                SDKSectionHeader(title: "Activity Log", subtext: "Filtered event stream.")
                VStack(spacing: 12) {
                    Picker("Filter", selection: $logFilter) {
                        ForEach(LogFilterType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if filteredActivityLog.isEmpty {
                        SDKModernCard { Text("No activity recorded.").sdkSubtext().frame(maxWidth: .infinity) }
                    } else {
                        ForEach(filteredActivityLog) { event in
                            SDKModernCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        SDKStatusPill(status: levelToStatus(event.level), text: event.level.rawValue.uppercased())
                                        Spacer()
                                        Text(event.timestamp.formatted(date: .omitted, time: .shortened)).font(.caption2).foregroundStyle(.tertiary)
                                    }
                                    Text(event.message).font(.subheadline.bold())

                                    if expandedLogID == event.id {
                                        Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                                            .font(.caption2).foregroundStyle(.secondary).padding(.top, 2)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { withAnimation { expandedLogID = expandedLogID == event.id ? nil : event.id } }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(connector.name)
        .sheet(isPresented: $showingAuth) {
            NavigationStack { ConnectorAuthView(connector: connector) }
                .presentationDetents([.medium, .large])
        }
        .alert("Disconnect \(connector.name)?", isPresented: $showingDisconnectAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) { connector.disconnect() }
        }
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionButton(title: String, icon: String, loading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                if loading { ProgressView().scaleEffect(0.8) }
            }
            .font(.subheadline.bold())
            .padding()
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(loading)
    }

    private func managementRow(title: String, icon: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).sdkSubtext()
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func levelToStatus(_ level: LogLevel) -> SDKStatus {
        switch level {
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        case .debug: return .info
        }
    }
}
