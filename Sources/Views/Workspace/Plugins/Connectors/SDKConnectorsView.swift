import SwiftUI

struct SDKConnectorsView: View {
    @StateObject private var manager = SDKConnectorManager.shared
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
                    HStack(spacing: 16) {
                        connectorStat(label: "Total", value: "\(connectorStats.total)", color: .blue)
                        connectorStat(label: "Connected", value: "\(connectorStats.connected)", color: .green)
                        connectorStat(label: "Disconnected", value: "\(connectorStats.disconnected)", color: .red)
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
                Section("Connectors") {
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
                                        if !connector.activityLog.isEmpty {
                                            Text("• \(connector.activityLog.count) events")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
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
                }
            }

            // MARK: - Quick Actions
            if !manager.connectors.isEmpty {
                Section("Quick Actions") {
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
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .bold()
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status == .connected ? Color.green.opacity(0.2) : Color.gray.opacity(0.2), in: Capsule())
            .foregroundStyle(status == .connected ? .green : .secondary)
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
                Section("Connector Type") {
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
                }

                Section("Configuration") {
                    TextField("Connector Name (optional)", text: $connectorName)
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
