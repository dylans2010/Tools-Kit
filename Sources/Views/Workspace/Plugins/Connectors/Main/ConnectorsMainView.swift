import SwiftUI

struct ConnectorsMainView: View {
    @StateObject private var manager = ConnectorManager.shared
    @StateObject private var sdkManager = SDKConnectorManager.shared
    @State private var showingBuilder = false
    @State private var showingDocs = false
    @State private var searchText = ""
    @State private var selectedFilter: ConnectorFilter = .all
    @State private var sortOrder: SortOrder = .name

    enum ConnectorFilter: String, CaseIterable, Sendable {
        case all = "All", active = "Active", inactive = "Inactive", error = "Errors"
    }

    enum SortOrder: String, CaseIterable, Sendable {
        case name = "Name", recent = "Recent", status = "Status"
    }

    var filteredConnectors: [ConnectorDefinition] {
        var result = manager.connectors
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.identifier.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch selectedFilter {
        case .all: break
        case .active: result = result.filter { $0.status == .active }
        case .inactive: result = result.filter { $0.status == .inactive }
        case .error: result = result.filter { $0.status == .error }
        }
        switch sortOrder {
        case .name: result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .recent: result.sort { $0.updatedAt > $1.updatedAt }
        case .status: result.sort { $0.status.rawValue < $1.status.rawValue }
        }
        return result
    }

    var body: some View {
        List {
            Section("Overview") {
                let conn = manager.connectors
                LabeledContent("Active", value: "\(conn.filter { $0.status == .active }.count)")
                LabeledContent("Errors", value: "\(conn.filter { $0.status == .error }.count)")
                LabeledContent("Endpoints", value: "\(conn.reduce(0) { $0 + $1.endpoints.count })")
            }

            Section("Filters") {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ConnectorFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
            }

            Section("Your Connectors") {
                if manager.connectors.isEmpty {
                    ContentUnavailableView(
                        "No Connectors",
                        systemImage: "cable.connector",
                        description: Text("Create your first connector to integrate external services.")
                    )
                } else if filteredConnectors.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search or filter.")
                    )
                } else {
                    ForEach(filteredConnectors) { connector in
                        NavigationLink {
                            ConnectorDefinitionDetailView(connector: connector)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(connector.name).font(.subheadline.bold())
                                    Spacer()
                                    Text(connector.status.rawValue.uppercased())
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(connectorStatusColor(connector.status))
                                }
                                Text(connector.identifier)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }

            Section("Platform Tools") {
                NavigationLink(destination: ConnectorBuilderView()) {
                    Label("Connector Builder", systemImage: "hammer")
                }
                NavigationLink(destination: SDKConnectorsView()) {
                    Label("SDK Connectors", systemImage: "puzzlepiece.extension")
                }
                NavigationLink(destination: ConnectorLogsView()) {
                    Label("Execution Logs", systemImage: "doc.text.magnifyingglass")
                }
                NavigationLink(destination: ConnectorSecurityView()) {
                    Label("Security & Scopes", systemImage: "lock.shield")
                }
            }

            Section {
                Button {
                    showingDocs = true
                } label: {
                    Label("View Documentation", systemImage: "book.closed")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Connectors")
        .searchable(text: $searchText, prompt: "Search connectors...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingBuilder = true } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingBuilder) {
            NavigationStack { ConnectorBuilderView() }
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingDocs) {
            ConnectorDocumentationView()
                .presentationDetents([.large])
        }
    }

    private func connectorStatusColor(_ status: ConnectorDefinition.ConnectorStatus) -> Color {
        switch status {
        case .active: return .primary
        case .inactive: return .secondary
        case .error: return .primary
        case .connecting: return .secondary
        }
    }
}

// MARK: - Detail View

struct ConnectorDefinitionDetailView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared
    @StateObject private var runtime = ConnectorRuntime.shared
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingTestConsole = false
    @State private var showingEndpointEditor = false
    @State private var newEndpointPath = ""
    @State private var newEndpointMethod = "GET"

    var isRunning: Bool { runtime.activeRunningConnectors.contains(connector.id) }

    var body: some View {
        List {
            Section("Status & Health") {
                LabeledContent("Name", value: connector.name)
                LabeledContent("Identifier") {
                    Text(connector.identifier)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Status") {
                    Text(connector.status.rawValue.capitalized)
                        .foregroundStyle(statusColor)
                }
                LabeledContent("Version", value: "v\(connector.version)")
                LabeledContent("Created", value: connector.createdAt.formatted(date: .abbreviated, time: .shortened))
                if connector.metadata.executionCount > 0 {
                    LabeledContent("Executions", value: "\(connector.metadata.executionCount)")
                    LabeledContent("Avg Latency", value: String(format: "%.0fms", connector.metadata.averageLatency))
                }
            }

            if !connector.description.isEmpty {
                Section("Description") {
                    Text(connector.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Quick Actions") {
                Button {
                    Task { await runtime.run(connector: connector) }
                } label: {
                    Label(isRunning ? "Running..." : "Execute Pipeline", systemImage: isRunning ? "arrow.triangle.2.circlepath" : "play.fill")
                }
                .disabled(isRunning)

                Button { showingTestConsole = true } label: {
                    Label("Open Test Console", systemImage: "terminal")
                }

                Button { toggleStatus() } label: {
                    Label(
                        connector.status == .active ? "Deactivate" : "Activate",
                        systemImage: connector.status == .active ? "pause.circle" : "checkmark.circle"
                    )
                }
            }

            Section("Endpoints (\(connector.endpoints.count))") {
                if connector.endpoints.isEmpty {
                    Text("No endpoints configured.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(connector.endpoints) { ep in
                        HStack {
                            Text(ep.method)
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .padding(4)
                                .background(.tint.opacity(0.1), in: Capsule())
                            Text(ep.path)
                                .font(.caption2.monospaced())
                                .lineLimit(1)
                        }
                    }
                    .onDelete {
                        connector.endpoints.remove(atOffsets: $0)
                        manager.updateConnector(connector)
                    }
                }
                Button { showingEndpointEditor = true } label: {
                    Label("Add Endpoint", systemImage: "plus.circle")
                }
            }

            Section("Configuration") {
                NavigationLink("Edit Identity", destination: ConnectorBuilderView())
                NavigationLink("Flow Builder", destination: ConnectorFlowBuilderView(connector: connector))
                NavigationLink("Schema Builder", destination: ConnectorSchemaBuilderView(connector: connector))
                NavigationLink("Security & Scopes", destination: ConnectorSecurityView(connector: connector))
            }

            Section("Operations") {
                NavigationLink("Live Execution", destination: ConnectorExecutionView(connector: connector))
                NavigationLink("Execution Logs", destination: ConnectorLogsView(connectorID: connector.id))
                NavigationLink("Versioning", destination: ConnectorVersioningView(connector: connector))
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Connector", systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(connector.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack { ConnectorBuilderView(connector: connector) }
        }
        .sheet(isPresented: $showingTestConsole) {
            NavigationStack { ConnectorTestConsoleView(connector: connector) }
        }
        .sheet(isPresented: $showingEndpointEditor) {
            NavigationStack {
                EndpointEditorSheet(path: $newEndpointPath, method: $newEndpointMethod) {
                    let ep = ConnectorEndpoint(path: newEndpointPath, method: newEndpointMethod, headers: [:], queryParams: [:])
                    connector.endpoints.append(ep)
                    manager.updateConnector(connector)
                    showingEndpointEditor = false
                }
            }
        }
        .alert("Delete?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { manager.deleteConnector(id: connector.id) }
        } message: {
            Text("Permanently remove \(connector.name)?")
        }
    }

    private var statusColor: Color {
        switch connector.status {
        case .active: return .green
        case .inactive: return .secondary
        case .error: return .red
        case .connecting: return .blue
        }
    }

    private func toggleStatus() {
        connector.status = (connector.status == .active ? .inactive : .active)
        connector.updatedAt = Date()
        manager.updateConnector(connector)
    }
}

struct EndpointEditorSheet: View {
    @Binding var path: String
    @Binding var method: String
    let onAdd: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section("New Endpoint") {
                TextField("Path", text: $path)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Picker("Method", selection: $method) {
                    ForEach(["GET", "POST", "PUT", "DELETE"], id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                Button("Add Endpoint") { onAdd() }
                    .frame(maxWidth: .infinity)
                    .bold()
                    .buttonStyle(.borderedProminent)
                    .disabled(path.isEmpty)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Add Endpoint")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

struct ConnectorDocumentationView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Architecture") {
                    Text("Connectors bridge ToolsKit with external REST APIs, supporting complex auth and multi-step flows.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("Lifecycle") {
                    Text("Connectors go through Inactive, Connecting, and Active states.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("Security") {
                    Text("All credentials are encrypted and stored securely using the system Keychain.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Documentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
