import SwiftUI

struct SDKConnectorsView: View {
    @StateObject private var manager = SDKConnectorManager.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var filterStatus: FilterStatus = .all
    @State private var sortOrder: SortOrder = .name
    @State private var showingBatchActions = false
    @State private var selectedConnectors: Set<UUID> = []

    enum FilterStatus: String, CaseIterable {
        case all = "All"
        case connected = "Connected"
        case disconnected = "Disconnected"
    }

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case type = "Type"
        case status = "Status"
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
        case .all: break
        case .connected: result = result.filter { $0.status == .connected }
        case .disconnected: result = result.filter { $0.status != .connected }
        }

        switch sortOrder {
        case .name: result = result.sorted { $0.name < $1.name }
        case .type: result = result.sorted { $0.type.rawValue < $1.type.rawValue }
        case .status: result = result.sorted { $0.status.rawValue < $1.status.rawValue }
        }

        return result
    }

    var connectorStats: (total: Int, connected: Int, disconnected: Int) {
        let total = manager.connectors.count
        let connected = manager.connectors.filter { $0.status == .connected }.count
        return (total: total, connected: connected, disconnected: total - connected)
    }

    var body: some View {
        List {
            // MARK: - Stats
            if !manager.connectors.isEmpty {
                Section {
                    SDKModernCard(padding: 12, content: {
                        HStack(spacing: 0) {
                            SDKStatPill(label: "Total", value: "\(connectorStats.total)", color: .blue)
                            SDKStatPill(label: "Connected", value: "\(connectorStats.connected)", color: .sdkSuccess)
                            SDKStatPill(label: "Offline", value: "\(connectorStats.disconnected)", color: .secondary)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                Section {
                    LabeledContent("Current Project", value: projectManager.currentProject?.name ?? "None")
                    LabeledContent("Active Links", value: "\(projectManager.currentProject?.enabledConnectorIDs.count ?? 0)")
                    LabeledContent("System Events", value: "\(logStore.entries.count)")
                } header: {
                    SDKSectionHeader("Project Integration", subtitle: "Active module utilization", alignment: .leading)
                }

                if let latestEvent = manager.connectors.flatMap({ $0.activityLog }).sorted(by: { $0.timestamp > $1.timestamp }).first {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(latestEvent.message).font(.subheadline)
                            Text(latestEvent.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        SDKSectionHeader("Latest Event", subtitle: "Real-time activity stream", alignment: .leading)
                    }
                }

                // MARK: - Filter & Sort
                Section {
                    Picker("Status", selection: $filterStatus) {
                        ForEach(FilterStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        .pickerStyle(.menu)

                        Spacer()

                        Text("\(filteredConnectors.count) connector(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // MARK: - Connectors List
            if filteredConnectors.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text(manager.connectors.isEmpty ? "No Connectors" : "No Results")
                            .font(.headline)
                        Text(manager.connectors.isEmpty
                            ? "Add a connector to integrate with external services."
                            : "No connectors match your current filter.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        if manager.connectors.isEmpty {
                            Button {
                                showingAddSheet = true
                            } label: {
                                Label("Add Connector", systemImage: "plus.circle.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            } else {
                Section {
                    ForEach(filteredConnectors, id: \.id) { connector in
                        NavigationLink(value: connector.id) {
                            HStack {
                                Image(systemName: icon(for: connector.type))
                                    .foregroundStyle(connector.status == .connected ? .blue : .secondary)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(connector.name)
                                        .font(.headline)
                                    HStack(spacing: 6) {
                                        Text(connector.type.rawValue.capitalized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("• \(connector.activityLog.count) events")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        if let current = projectManager.currentProject,
                                           current.enabledConnectorIDs.contains(connector.id) {
                                            Text("• Project enabled")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    if let latest = connector.activityLog.first {
                                        Text(latest.message)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                statusBadge(connector.status)
                            }
                        }
                        .contextMenu {
                            Button {
                                Task { try? await connector.testConnection() }
                            } label: {
                                Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                            }
                            Button {
                                Task { try? await connector.sync() }
                            } label: {
                                Label("Force Sync", systemImage: "arrow.clockwise")
                            }
                            Divider()
                            Button(role: .destructive) {
                                manager.remove(id: connector.id)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteConnectors)
                } header: {
                    Text("Connectors")
                }
            }

            // MARK: - Quick Actions
            if !manager.connectors.isEmpty {
                Section {
                    Button {
                        Task {
                            for connector in manager.connectors {
                                try? await connector.testConnection()
                            }
                        }
                    } label: {
                        Label("Test All Connections", systemImage: "antenna.radiowaves.left.and.right")
                    }

                    Button {
                        Task {
                            for connector in manager.connectors {
                                try? await connector.sync()
                            }
                        }
                    } label: {
                        Label("Sync All Connectors", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("Quick Actions")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search connectors...")
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
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddConnectorView()
        }
    }

    // MARK: - Helpers

    private func connectorStat(label: String, value: String, color: Color) -> some View {
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

    private func icon(for type: ConnectorType) -> String {
        switch type {
        case .gmail: return "envelope.fill"
        case .webhook: return "network"
        case .github: return "terminal.fill"
        case .localFileSystem: return "folder.fill"
        case .calendar: return "calendar"
        }
    }

    private func statusBadge(_ status: ConnectorStatus) -> some View {
        SDKStatusPill(
            status.rawValue,
            systemImage: status == .connected ? "checkmark.circle.fill" : "xmark.circle.fill",
            color: status == .connected ? .sdkSuccess : .secondary
        )
    }

    private func deleteConnectors(at offsets: IndexSet) {
        let connectors = filteredConnectors
        offsets.forEach { index in
            let id = connectors[index].id
            manager.remove(id: id)
        }
    }
}

struct AddConnectorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: ConnectorType = .gmail
    @State private var connectorName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(ConnectorType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: typeIcon(type))
                                Text(type.rawValue.capitalized)
                            }
                            .tag(type)
                        }
                    }

                    Text(typeDescription(selectedType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Connector Type")
                }

                Section {
                    TextField("Connector Name (optional)", text: $connectorName)
                } header: {
                    Text("Configuration")
                }

                Section {
                    Button("Create Connector") {
                        createConnector()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .bold()
                }
            }
            .navigationTitle("Add Connector")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func typeIcon(_ type: ConnectorType) -> String {
        switch type {
        case .gmail: return "envelope.fill"
        case .webhook: return "network"
        case .github: return "terminal.fill"
        case .localFileSystem: return "folder.fill"
        case .calendar: return "calendar"
        }
    }

    private func typeDescription(_ type: ConnectorType) -> String {
        switch type {
        case .gmail: return "Connect to Gmail for email integration and automation."
        case .webhook: return "Set up webhook endpoints for real-time event processing."
        case .github: return "Integrate with GitHub repositories and workflows."
        case .localFileSystem: return "Access and manage local files and directories."
        case .calendar: return "Sync with calendar services for scheduling."
        }
    }

    private func createConnector() {
        let connector: any BaseConnector
        switch selectedType {
        case .gmail: connector = GmailConnector()
        case .webhook: connector = WebhookConnector()
        case .github: connector = GitHubConnector()
        case .localFileSystem: connector = LocalFileConnector()
        case .calendar: connector = CalendarConnector()
        }
        SDKConnectorManager.shared.register(connector)
    }
}
