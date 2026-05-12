import SwiftUI

struct SDKConnectorsView: View {
    @StateObject private var manager = SDKConnectorManager.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var filterStatus: FilterStatus = .all
    @State private var sortOrder: SortOrder = .name

    @State private var syncingIDs: Set<UUID> = []
    @State private var reconnectAttempts: [UUID: Int] = [:]
    @State private var lastErrors: [UUID: String] = [:]
    @State private var inspectingConnectorID: UUID?

    enum FilterStatus: String, CaseIterable, Sendable {
        case all = "All"
        case connected = "Connected"
        case disconnected = "Disconnected"
        case syncing = "Syncing"
        case error = "Error"
    }

    enum SortOrder: String, CaseIterable, Sendable {
        case name = "Name"
        case type = "Type"
        case status = "Status"
    }

    enum ConnectorLifecycleState: String, Sendable {
        case connected
        case disconnected
        case syncing
        case error
    }

    var filteredConnectors: [any BaseConnector] {
        var result = manager.connectors

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch filterStatus {
        case .all:
            break
        case .connected:
            result = result.filter { lifecycleState(for: $0) == .connected }
        case .disconnected:
            result = result.filter { lifecycleState(for: $0) == .disconnected }
        case .syncing:
            result = result.filter { lifecycleState(for: $0) == .syncing }
        case .error:
            result = result.filter { lifecycleState(for: $0) == .error }
        }

        switch sortOrder {
        case .name:
            result = result.sorted { $0.name < $1.name }
        case .type:
            result = result.sorted { $0.type.rawValue < $1.type.rawValue }
        case .status:
            result = result.sorted { lifecycleState(for: $0).rawValue < lifecycleState(for: $1).rawValue }
        }

        return result
    }

    var body: some View {
        List {
            Section("Lifecycle Overview") {
                LabeledContent("Connected", value: "\(manager.connectors.filter { lifecycleState(for: $0) == .connected }.count)")
                LabeledContent("Disconnected", value: "\(manager.connectors.filter { lifecycleState(for: $0) == .disconnected }.count)")
                LabeledContent("Syncing", value: "\(manager.connectors.filter { lifecycleState(for: $0) == .syncing }.count)")
                LabeledContent("Errors", value: "\(manager.connectors.filter { lifecycleState(for: $0) == .error }.count)")
                LabeledContent("Project Links", value: "\(projectManager.currentProject?.enabledConnectorIDs.count ?? 0)")
            }

            if !manager.connectors.isEmpty {
                Section("Filters") {
                    Picker("Status", selection: $filterStatus) {
                        ForEach(FilterStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Picker("Sort", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
            }

            Section("Connectors") {
                if filteredConnectors.isEmpty {
                    ContentUnavailableView(
                        manager.connectors.isEmpty ? "No Connectors" : "No Results",
                        systemImage: "puzzlepiece.extension",
                        description: Text(manager.connectors.isEmpty ? "Register SDK connectors to integrate external modules." : "No modules match your current filter.")
                    )
                } else {
                    ForEach(filteredConnectors, id: \.id) { connector in
                        NavigationLink(value: connector.id) {
                            SDKConnectorRow(
                                connector: connector,
                                lifecycleState: lifecycleState(for: connector),
                                attemptCount: reconnectAttempts[connector.id, default: 0],
                                lastError: lastErrors[connector.id]
                            )
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                manager.remove(id: connector.id)
                                lastErrors[connector.id] = nil
                                reconnectAttempts[connector.id] = nil
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                inspectingConnectorID = connector.id
                            } label: {
                                Label("Inspect", systemImage: "info.circle")
                            }
                            Button {
                                reconnect(connector)
                            } label: {
                                Label("Reconnect", systemImage: "arrow.clockwise")
                            }
                            .disabled(syncingIDs.contains(connector.id))
                        }
                    }
                }
            }

            if !manager.connectors.isEmpty {
                Section("Diagnostics") {
                    let connectedCount = manager.connectors.filter { lifecycleState(for: $0) == .connected }.count
                    let errorCount = manager.connectors.filter { lifecycleState(for: $0) == .error }.count
                    let totalRetries = reconnectAttempts.values.reduce(0, +)

                    LabeledContent("Health") {
                        Text(errorCount == 0 ? "Healthy" : "Degraded")
                            .foregroundStyle(errorCount == 0 ? Color.green : Color.orange)
                    }
                    LabeledContent("Connection Rate", value: "\(connectedCount)/\(manager.connectors.count)")
                    LabeledContent("Total Retries", value: "\(totalRetries)")
                    LabeledContent("Active Errors", value: "\(lastErrors.count)")

                    if !lastErrors.isEmpty {
                        ForEach(Array(lastErrors.keys), id: \.self) { id in
                            if let connector = manager.connector(for: id), let error = lastErrors[id] {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(connector.name).font(.caption.bold())
                                    Text(error).font(.caption2).foregroundStyle(.red)
                                }
                            }
                        }
                    }
                }

                Section("Operations") {
                    Button {
                        refreshStatuses()
                    } label: {
                        Label("Manual Refresh", systemImage: "arrow.clockwise")
                    }

                    Button {
                        Task {
                            for connector in manager.connectors {
                                reconnect(connector)
                            }
                        }
                    } label: {
                        Label("Reconnect Disconnected", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button {
                        Task {
                            for connector in manager.connectors {
                                await runSync(connector)
                            }
                        }
                    } label: {
                        Label("Sync All Connectors", systemImage: "arrow.trianglehead.2.clockwise")
                    }

                    Button {
                        reconnectAttempts.removeAll()
                        lastErrors.removeAll()
                    } label: {
                        Label("Clear Diagnostics", systemImage: "xmark.circle")
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search modules...")
        .navigationTitle("SDK Connectors")
        .navigationDestination(for: UUID.self) { id in
            if let connector = manager.connectors.first(where: { $0.id == id }) as? GmailConnector {
                ConnectorDetailView(connector: connector)
            } else if let connector = manager.connectors.first(where: { $0.id == id }) as? GitHubConnector {
                ConnectorDetailView(connector: connector)
            } else if let connector = manager.connectors.first(where: { $0.id == id }) as? WebhookConnector {
                ConnectorDetailView(connector: connector)
            } else if let connector = manager.connectors.first(where: { $0.id == id }) as? CalendarConnector {
                ConnectorDetailView(connector: connector)
            } else if let connector = manager.connectors.first(where: { $0.id == id }) as? LocalFileConnector {
                ConnectorDetailView(connector: connector)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ConnectorBuilderView()
        }
        .sheet(item: Binding<InspectionItem?>(
            get: {
                guard let id = inspectingConnectorID,
                      let connector = manager.connector(for: id) else {
                    return nil
                }
                return InspectionItem(connectorID: id, title: connector.name)
            },
            set: { item in inspectingConnectorID = item?.connectorID }
        )) { item in
            ConnectorStatusInspectorView(
                connector: manager.connector(for: item.connectorID),
                lifecycleState: manager.connector(for: item.connectorID).map(lifecycleState),
                retryCount: reconnectAttempts[item.connectorID, default: 0],
                lastError: lastErrors[item.connectorID]
            )
        }
        .onAppear(perform: refreshStatuses)
    }

    private func lifecycleState(for connector: any BaseConnector) -> ConnectorLifecycleState {
        if syncingIDs.contains(connector.id) {
            return .syncing
        }
        if lastErrors[connector.id] != nil || connector.status == .error {
            return .error
        }
        return connector.status == .connected ? .connected : .disconnected
    }

    private func refreshStatuses() {
        for connector in manager.connectors {
            Task {
                do {
                    _ = try await connector.testConnection()
                    await MainActor.run { lastErrors[connector.id] = nil }
                } catch {
                    await MainActor.run { lastErrors[connector.id] = error.localizedDescription }
                }
            }
        }
    }

    private func reconnect(_ connector: any BaseConnector) {
        Task {
            await runReconnect(connector)
        }
    }

    private func runReconnect(_ connector: any BaseConnector) async {
        await MainActor.run {
            syncingIDs.insert(connector.id)
            reconnectAttempts[connector.id, default: 0] += 1
            lastErrors[connector.id] = nil
        }

        defer {
            Task { @MainActor in
                syncingIDs.remove(connector.id)
            }
        }

        for _ in 0..<3 {
            do {
                _ = try await connector.testConnection()
                if connector.status == .connected {
                    try? await connector.sync()
                }
                await MainActor.run { lastErrors[connector.id] = nil }
                return
            } catch {
                await MainActor.run { lastErrors[connector.id] = error.localizedDescription }
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
    }

    private func runSync(_ connector: any BaseConnector) async {
        await MainActor.run {
            syncingIDs.insert(connector.id)
            lastErrors[connector.id] = nil
        }

        defer {
            Task { @MainActor in
                syncingIDs.remove(connector.id)
            }
        }

        do {
            try await connector.sync()
        } catch {
            await MainActor.run { lastErrors[connector.id] = error.localizedDescription }
        }
    }
}

private struct SDKConnectorRow: View {
    let connector: any BaseConnector
    let lifecycleState: SDKConnectorsView.ConnectorLifecycleState
    let attemptCount: Int
    let lastError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(connector.name, systemImage: icon(for: connector.type))
                    .font(.subheadline)
                Spacer()
                Text(lifecycleState.rawValue.uppercased())
                    .font(.caption2)
            }

            Text("Type: \(connector.type.rawValue.capitalized)")
                .font(.caption)

            Text("Retries: \(attemptCount)")
                .font(.caption2)

            if let lastError, lifecycleState == .error {
                Text(lastError)
                    .font(.caption2)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private func icon(for type: ConnectorType) -> String {
        switch type {
        case .gmail: return "envelope"
        case .webhook: return "network"
        case .github: return "terminal"
        case .localFileSystem: return "folder"
        case .calendar: return "calendar"
        case .rest: return "globe"
        case .mqtt: return "antenna.radiowaves.left.and.right"
        }
    }
}

private struct InspectionItem: Identifiable, Sendable {
    let connectorID: UUID
    let title: String
    var id: UUID { connectorID }
}

private struct ConnectorStatusInspectorView: View {
    let connector: (any BaseConnector)?
    let lifecycleState: SDKConnectorsView.ConnectorLifecycleState?
    let retryCount: Int
    let lastError: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    LabeledContent("Lifecycle", value: lifecycleState?.rawValue.capitalized ?? "Unknown")
                    LabeledContent("Retries", value: "\(retryCount)")
                    LabeledContent("Connector Status", value: connector?.status.rawValue.capitalized ?? "Unknown")
                    LabeledContent("Log Entries", value: "\(connector?.activityLog.count ?? 0)")
                }

                if let lastError {
                    Section("Last Error") {
                        Text(lastError)
                            .font(.caption)
                    }
                }

                Section("Recent Activity") {
                    if let connector {
                        if connector.activityLog.isEmpty {
                            Text("No activity events yet.")
                                .font(.caption)
                        } else {
                            ForEach(connector.activityLog.prefix(15)) { event in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.message)
                                        .font(.caption)
                                    Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                }
                            }
                        }
                    } else {
                        Text("Connector unavailable.")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(connector?.name ?? "Status")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
