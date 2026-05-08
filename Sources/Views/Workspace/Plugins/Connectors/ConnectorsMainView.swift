import SwiftUI

struct ConnectorsMainView: View {
    @StateObject private var manager = ConnectorManager.shared
    @StateObject private var sdkManager = SDKConnectorManager.shared
    @State private var showingBuilder = false
    @State private var showingDocs = false
    @State private var searchText = ""
    @State private var selectedFilter: ConnectorFilter = .all
    @State private var sortOrder: SortOrder = .name

    enum ConnectorFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case inactive = "Inactive"
        case error = "Errors"
    }

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case recent = "Recent"
        case status = "Status"
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
        let connectors = manager.connectors
        let activeCount = connectors.filter { $0.status == .active }.count
        let errorCount = connectors.filter { $0.status == .error }.count
        let connectingCount = connectors.filter { $0.status == .connecting }.count
        let totalEndpoints = connectors.reduce(0) { $0 + $1.endpoints.count }
        let totalFlowSteps = connectors.reduce(0) { $0 + $1.flow.steps.count }
        let avgLatency = connectors.isEmpty ? 0.0 : connectors.reduce(0.0) { $0 + $1.metadata.averageLatency } / Double(connectors.count)

        return List {
            // MARK: - Dashboard Header
            Section {
                SDKModernCard {
                    VStack(alignment: .center, spacing: 14) {
                        SDKSectionHeader("Connectors Platform", subtitle: "Advanced external API federation engine", systemImage: "cable.connector")

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            statView(label: "Total", value: "\(connectors.count)", color: .blue, icon: "puzzlepiece.extension")
                            statView(label: "Active", value: "\(activeCount)", color: .sdkSuccess, icon: "checkmark.circle.fill")
                            statView(label: "Errors", value: "\(errorCount)", color: .sdkError, icon: "exclamationmark.triangle.fill")
                            statView(label: "Latency", value: String(format: "%.0fms", avgLatency), color: .teal, icon: "speedometer")
                            statView(label: "Endpoints", value: "\(totalEndpoints)", color: .purple, icon: "point.3.connected.trianglepath.dotted")
                            statView(label: "Waiting", value: "\(connectingCount)", color: .sdkWarning, icon: "arrow.triangle.2.circlepath")
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            // MARK: - Quick Actions
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        quickActionButton(title: "New Connector", icon: "plus.circle.fill", color: .blue) {
                            showingBuilder = true
                        }
                        quickActionButton(title: "Run All Active", icon: "play.circle.fill", color: .green) {
                            Task {
                                for connector in connectors where connector.status == .active {
                                    await ConnectorRuntime.shared.run(connector: connector)
                                }
                            }
                        }
                        quickActionButton(title: "Sync All SDK", icon: "arrow.triangle.2.circlepath.circle.fill", color: .orange) {
                            Task { try? await sdkManager.syncAll() }
                        }
                        quickActionButton(title: "View Docs", icon: "book.circle.fill", color: .purple) {
                            showingDocs = true
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Quick Actions")
            }

            // MARK: - Filter & Search Controls
            if !connectors.isEmpty {
                Section {
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(ConnectorFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Sort by")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }

            // MARK: - Your Connectors
            Section {
                if filteredConnectors.isEmpty && connectors.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Connectors Created")
                            .font(.headline)
                        Text("Build your first integration engine to connect external services.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)

                        Button("Create Connector") {
                            showingBuilder = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else if filteredConnectors.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No connectors match your filter.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    ForEach(filteredConnectors) { connector in
                        NavigationLink {
                            ConnectorDefinitionDetailView(connector: connector)
                        } label: {
                            connectorRow(connector)
                        }
                    }
                    .onDelete { indices in
                        let sorted = filteredConnectors
                        for index in indices {
                            let connector = sorted[index]
                            manager.deleteConnector(id: connector.id)
                        }
                    }
                }
            } header: {
                Text("Your Connectors")
            }

            // MARK: - Platform Tools
            Section {
                NavigationLink(destination: ConnectorLogsView()) {
                    Label("Global Execution Logs", systemImage: "list.bullet.rectangle")
                }
                NavigationLink(destination: ConnectorSecurityView()) {
                    Label("Security & Scopes", systemImage: "shield.lefthalf.filled")
                }
                NavigationLink(destination: ConnectorBuilderView()) {
                    Label("Connector Builder", systemImage: "plus.rectangle.on.folder")
                }
                if let first = connectors.first {
                    NavigationLink(destination: ConnectorExecutionView(connector: first)) {
                        Label("Connector Execution", systemImage: "play.circle")
                    }
                    NavigationLink(destination: ConnectorFlowBuilderView(connector: first)) {
                        Label("Connector Flow Builder", systemImage: "arrow.triangle.branch")
                    }
                    NavigationLink(destination: ConnectorScopeView(connector: first)) {
                        Label("Connector Scope Assignment", systemImage: "lock.shield")
                    }
                }
                NavigationLink(destination: SDKConnectorsView()) {
                    Label("SDK Connectors", systemImage: "cable.connector")
                }
                Button {
                    showingDocs = true
                } label: {
                    Label("Connectors Documentation", systemImage: "book.closed")
                }
            } header: {
                Text("Platform Tools")
            }

            // MARK: - Analytics Overview
            if !connectors.isEmpty {
                Section {
                    let totalExecs = connectors.reduce(0) { $0 + $1.metadata.executionCount }
                    let avgError = connectors.isEmpty ? 0.0 : connectors.reduce(0.0) { $0 + $1.metadata.errorRate } / Double(connectors.count)

                    LabeledContent("Total Executions") {
                        Text("\(totalExecs)")
                            .bold()
                            .foregroundColor(.blue)
                    }
                    LabeledContent("Average Error Rate") {
                        Text(String(format: "%.1f%%", avgError * 100))
                            .bold()
                            .foregroundColor(avgError > 0.1 ? .red : .green)
                    }
                    LabeledContent("Total Flow Steps") {
                        Text("\(totalFlowSteps)")
                            .bold()
                    }
                    LabeledContent("Connectors with Flows") {
                        Text("\(connectors.filter { !$0.flow.steps.isEmpty }.count)")
                            .bold()
                    }

                    if let lastExecuted = connectors.compactMap({ $0.metadata.lastExecutedAt }).max() {
                        LabeledContent("Last Execution") {
                            Text(lastExecuted.formatted(.relative(presentation: .numeric)))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Analytics Overview")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search connectors...")
        .navigationTitle("Connectors")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingBuilder = true
                    } label: {
                        Label("New Connector", systemImage: "plus")
                    }
                    Button {
                        showingDocs = true
                    } label: {
                        Label("Documentation", systemImage: "book.closed")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingBuilder) {
            NavigationView {
                ConnectorBuilderView()
            }
        }
        .sheet(isPresented: $showingDocs) {
            ConnectorDocumentationView()
        }
    }

    // MARK: - Connector Row

    private func connectorRow(_ connector: ConnectorDefinition) -> some View {
        SDKModernCard(padding: 12) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(connector.name)
                        .font(.subheadline.bold())
                    Text(connector.identifier)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.tertiary)

                    HStack(spacing: 10) {
                        if !connector.endpoints.isEmpty {
                            Label("\(connector.endpoints.count)", systemImage: "network").font(.system(size: 9))
                        }
                        if !connector.flow.steps.isEmpty {
                            Label("\(connector.flow.steps.count)", systemImage: "arrow.triangle.branch").font(.system(size: 9))
                        }
                        if connector.metadata.executionCount > 0 {
                            Label("\(connector.metadata.executionCount)", systemImage: "play.circle").font(.system(size: 9))
                        }
                    }
                    .foregroundColor(.secondary)
                }
                Spacer()
                SDKStatusPill(connector.status.rawValue, color: statusColor(connector.status), isCapsule: false)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func statView(label: String, value: String, color: Color, icon: String) -> some View {
        SDKStatPill(label: label, value: value, color: color, icon: icon)
    }

    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            .frame(width: 80, height: 70)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func connectorStatusPill(status: ConnectorDefinition.ConnectorStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .foregroundColor(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: ConnectorDefinition.ConnectorStatus) -> Color {
        switch status {
        case .active: return .green
        case .inactive: return .secondary
        case .error: return .red
        case .connecting: return .blue
        }
    }
}

// MARK: - Connector Definition Detail

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

    var isRunning: Bool {
        runtime.activeRunningConnectors.contains(connector.id)
    }

    var body: some View {
        List {
            // MARK: - Status & Health
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(connector.name)
                            .font(.title3.bold())
                        Text(connector.identifier)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    statusBadge(connector.status)
                }

                LabeledContent("Version", value: "v\(connector.version)")
                LabeledContent("Created", value: connector.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Updated", value: connector.updatedAt.formatted(date: .abbreviated, time: .shortened))

                if connector.metadata.executionCount > 0 {
                    LabeledContent("Executions", value: "\(connector.metadata.executionCount)")
                    LabeledContent("Avg Latency", value: String(format: "%.0fms", connector.metadata.averageLatency))
                    LabeledContent("Error Rate") {
                        Text(String(format: "%.1f%%", connector.metadata.errorRate * 100))
                            .foregroundColor(connector.metadata.errorRate > 0.1 ? .red : .green)
                    }
                    if let lastExec = connector.metadata.lastExecutedAt {
                        LabeledContent("Last Executed", value: lastExec.formatted(.relative(presentation: .numeric)))
                    }
                }
            } header: {
                Text("Status & Health")
            }

            if !connector.description.isEmpty {
                Section {
                    Text(connector.description)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Description")
                }
            }

            // MARK: - Quick Actions
            Section {
                Button {
                    Task { await runtime.run(connector: connector) }
                } label: {
                    Label(isRunning ? "Running..." : "Execute Pipeline", systemImage: isRunning ? "arrow.triangle.2.circlepath" : "play.fill")
                        .foregroundColor(isRunning ? .secondary : .green)
                }
                .disabled(isRunning)

                Button {
                    showingTestConsole = true
                } label: {
                    Label("Open Test Console", systemImage: "terminal")
                }

                Button {
                    toggleConnectorStatus()
                } label: {
                    Label(
                        connector.status == .active ? "Deactivate Connector" : "Activate Connector",
                        systemImage: connector.status == .active ? "pause.circle" : "checkmark.circle"
                    )
                    .foregroundColor(connector.status == .active ? .orange : .green)
                }

                Button {
                    duplicateConnector()
                } label: {
                    Label("Duplicate Connector", systemImage: "doc.on.doc")
                }
            } header: {
                Text("Quick Actions")
            }

            // MARK: - Endpoints
            Section {
                if connector.endpoints.isEmpty {
                    Text("No endpoints configured")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(connector.endpoints) { endpoint in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(endpoint.method)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(methodColor(endpoint.method).opacity(0.15))
                                    .foregroundColor(methodColor(endpoint.method))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text(endpoint.path)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .lineLimit(1)
                            }

                            if !endpoint.headers.isEmpty {
                                Text("\(endpoint.headers.count) headers")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { indices in
                        connector.endpoints.remove(atOffsets: indices)
                        manager.updateConnector(connector)
                    }
                }

                Button {
                    showingEndpointEditor = true
                } label: {
                    Label("Add Endpoint", systemImage: "plus.circle")
                }
            } header: {
                Text("Endpoints (\(connector.endpoints.count))")
            }

            // MARK: - Navigation to All Configuration Views
            Section {
                NavigationLink(destination: ConnectorBuilderView(connector: connector)) {
                    Label("Edit Identity", systemImage: "pencil.circle")
                }
                NavigationLink(destination: ConnectorFlowBuilderView(connector: connector)) {
                    Label("Flow Builder", systemImage: "arrow.triangle.branch")
                }
                NavigationLink(destination: ConnectorSchemaBuilderView(connector: connector)) {
                    Label("Schema Builder", systemImage: "doc.text.magnifyingglass")
                }
                NavigationLink(destination: ConnectorSecurityView(connector: connector)) {
                    Label("Security & Scopes", systemImage: "shield.lefthalf.filled")
                }
                NavigationLink(destination: ConnectorScopeView(connector: connector)) {
                    Label("Scope Assignment", systemImage: "lock.shield")
                }
            } header: {
                Text("Configuration")
            }

            Section {
                NavigationLink(destination: ConnectorExecutionView(connector: connector)) {
                    Label("Live Execution", systemImage: "play.circle")
                }
                NavigationLink(destination: ConnectorLogsView(connectorID: connector.id)) {
                    Label("Execution Logs", systemImage: "list.bullet.rectangle")
                }
                NavigationLink(destination: ConnectorVersioningView(connector: connector)) {
                    Label("Versioning & Releases", systemImage: "clock.arrow.circlepath")
                }
            } header: {
                Text("Operations")
            }

            // MARK: - Auth Configuration
            Section {
                LabeledContent("Auth Type", value: connector.authConfig.type.rawValue.capitalized)

                if connector.authConfig.type == .oauth2, let oauth = connector.authConfig.oauthConfig {
                    LabeledContent("Client ID") {
                        Text(String(oauth.clientID.prefix(8)) + "...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    LabeledContent("Scopes", value: oauth.scopes.joined(separator: ", "))
                }

                if !connector.authConfig.credentials.isEmpty {
                    LabeledContent("Stored Credentials", value: "\(connector.authConfig.credentials.count) keys")
                }
            } header: {
                Text("Authentication")
            }

            // MARK: - Danger Zone
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Connector", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(connector.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        showingTestConsole = true
                    } label: {
                        Label("Test Console", systemImage: "terminal")
                    }
                    Button {
                        duplicateConnector()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                ConnectorBuilderView(connector: connector)
            }
        }
        .sheet(isPresented: $showingTestConsole) {
            NavigationView {
                ConnectorTestConsoleView(connector: connector)
            }
        }
        .sheet(isPresented: $showingEndpointEditor) {
            NavigationView {
                endpointEditorSheet
            }
        }
        .alert("Delete Connector?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                manager.deleteConnector(id: connector.id)
            }
        } message: {
            Text("This will permanently delete '\(connector.name)' and all its configuration. This action cannot be undone.")
        }
    }

    // MARK: - Endpoint Editor Sheet

    private var endpointEditorSheet: some View {
        Form {
            Section {
                TextField("URL Path (e.g. https://api.example.com/data)", text: $newEndpointPath)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Picker("Method", selection: $newEndpointMethod) {
                    ForEach(["GET", "POST", "PUT", "DELETE", "PATCH"], id: \.self) { method in
                        Text(method).tag(method)
                    }
                }
            } header: {
                Text("New Endpoint")
            }

            Section {
                Button("Add Endpoint") {
                    let endpoint = ConnectorEndpoint(
                        path: newEndpointPath,
                        method: newEndpointMethod,
                        headers: [:],
                        queryParams: [:]
                    )
                    connector.endpoints.append(endpoint)
                    manager.updateConnector(connector)
                    newEndpointPath = ""
                    newEndpointMethod = "GET"
                    showingEndpointEditor = false
                }
                .disabled(newEndpointPath.isEmpty)
            }
        }
        .navigationTitle("Add Endpoint")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { showingEndpointEditor = false }
            }
        }
    }

    // MARK: - Helpers

    private func statusBadge(_ status: ConnectorDefinition.ConnectorStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 8, height: 8)
            Text(status.rawValue.capitalized)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(statusColor(status))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor(status).opacity(0.12))
        .clipShape(Capsule())
    }

    private func statusColor(_ status: ConnectorDefinition.ConnectorStatus) -> Color {
        switch status {
        case .active: return .green
        case .inactive: return .secondary
        case .error: return .red
        case .connecting: return .blue
        }
    }

    private func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .secondary
        }
    }

    private func toggleConnectorStatus() {
        if connector.status == .active {
            connector.status = .inactive
        } else {
            connector.status = .active
        }
        connector.updatedAt = Date()
        manager.updateConnector(connector)
    }

    private func duplicateConnector() {
        let duplicate = ConnectorDefinition(
            id: UUID(),
            name: "\(connector.name) (Copy)",
            identifier: "\(connector.identifier).copy",
            version: connector.version,
            description: connector.description,
            authConfig: connector.authConfig,
            schema: connector.schema,
            flow: connector.flow
        )
        manager.addConnector(duplicate)
    }
}

// MARK: - Connector Documentation

struct ConnectorDocumentationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Picker("Section", selection: $selectedTab) {
                        Text("Overview").tag(0)
                        Text("Auth").tag(1)
                        Text("Flows").tag(2)
                        Text("Troubleshoot").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch selectedTab {
                    case 0: overviewDocs
                    case 1: authDocs
                    case 2: flowDocs
                    case 3: troubleshootDocs
                    default: overviewDocs
                    }
                }
                .padding()
            }
            .navigationTitle("Documentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var overviewDocs: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Connector Platform Documentation")
                .font(.title.bold())

            docSection(title: "Architecture", content: "Connectors are dedicated integration engines that bridge ToolsKit with external REST APIs. They support complex authentication, schema mapping, and multi-step workflow pipelines.")

            docSection(title: "How to Connect APIs", content: "1. Create a new connector with a unique identifier.\n2. Define endpoints with path, method, and headers.\n3. Configure the Auth Strategy (API Key, Bearer, or OAuth2).\n4. Map response fields to workspace models using the Schema Builder.\n5. Build automation flows with the Flow Builder.\n6. Test your connector using the Test Console.")

            docSection(title: "Connector Lifecycle", content: "Connectors go through several states:\n\n- Inactive: Created but not activated\n- Connecting: Authentication in progress\n- Active: Ready for execution\n- Error: Something went wrong")

            codeExample(title: "Example Endpoint", code: "GET https://api.example.com/v1/data\nHeaders: Authorization: Bearer <token>\nContent-Type: application/json")
        }
    }

    private var authDocs: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Authentication Setup")
                .font(.title2.bold())

            docSection(title: "Supported Auth Types", content: "- None: No authentication required\n- API Key: Send a key in a custom header\n- Bearer Token: Standard Authorization header\n- OAuth2: Full token exchange with automatic refresh")

            docSection(title: "OAuth2 Configuration", content: "For OAuth2, you need to provide:\n1. Client ID and Client Secret\n2. Authorization URL and Token URL\n3. Required scopes\n\nThe platform handles token exchange and automatic background refreshing.")

            docSection(title: "Credential Storage", content: "All credentials are encrypted and stored securely using the system Keychain. Credentials are never stored in plain text and are isolated per connector.")

            codeExample(title: "API Key Example", code: "Header Name: X-API-Key\nHeader Value: sk-abc123...\n\nThe key is securely stored and injected\ninto every request automatically.")
        }
    }

    private var flowDocs: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Building Flows")
                .font(.title2.bold())

            docSection(title: "Flow Architecture", content: "Use the visual Flow Designer to create Trigger-Condition-Action pipelines. Connectors can be triggered by workspace events or external webhooks.")

            docSection(title: "Step Types", content: "- Trigger: Initiates the flow (e.g., on schedule, on event)\n- Condition: JavaScript expression that must be true to continue\n- Action: Execute an API endpoint\n- Delay: Wait a specified number of seconds")

            docSection(title: "Best Practices", content: "1. Always start with a Trigger step\n2. Add Conditions before destructive Actions\n3. Use Delays to respect rate limits\n4. Keep flows focused on a single task\n5. Test with the Test Console before enabling")

            codeExample(title: "Example Flow", code: "Trigger: note.created\nCondition: content.includes('ticket')\nAction: POST https://api.jira.com/issue\nDelay: 2 seconds")
        }
    }

    private var troubleshootDocs: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Troubleshooting Guide")
                .font(.title2.bold())

            docSection(title: "Connection Failures", content: "1. Verify the endpoint URL is correct and accessible\n2. Check that authentication credentials are valid\n3. Ensure TLS is enabled if required\n4. Review the Execution Logs for detailed error messages")

            docSection(title: "Flow Execution Errors", content: "1. Check that all endpoints referenced in actions exist\n2. Verify JavaScript conditions are syntactically correct\n3. Ensure rate limits are not being exceeded\n4. Check the connector status is 'Active'")

            docSection(title: "Schema Mapping Issues", content: "1. Validate your JSON schema against the API response\n2. Ensure field mappings match the actual response structure\n3. Use the Test Console to inspect raw responses\n4. Check for nested objects that need dot-notation paths")

            docSection(title: "Performance Issues", content: "1. Monitor average latency in the connector details\n2. Add appropriate Delay steps to respect rate limits\n3. Reduce the number of flow steps where possible\n4. Check the Security settings for rate limiting configuration")
        }
    }

    private func docSection(title: String, content: String) -> some View {
        Group {
            Text(title)
                .font(.headline)
            Text(content)
                .foregroundColor(.secondary)
        }
    }

    private func codeExample(title: String, code: String) -> some View {
        Group {
            Text(title)
                .font(.subheadline.bold())
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.05))
                .cornerRadius(8)
        }
    }
}
