import SwiftUI

struct ConnectorsMainView: View {
    @StateObject private var manager = ConnectorManager.shared
    @StateObject private var sdkManager = SDKConnectorManager.shared
    @State private var showingBuilder = false
    @State private var showingDocs = false
    @State private var searchText = ""
    @State private var selectedFilter: ConnectorFilter = .all

    enum ConnectorFilter: String, CaseIterable {
        case all = "All", active = "Active", error = "Errors"
    }

    var filteredConnectors: [ConnectorDefinition] {
        var result = manager.connectors
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.identifier.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch selectedFilter {
        case .all: break
        case .active: result = result.filter { $0.status == .active }
        case .error: result = result.filter { $0.status == .error }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SDKSectionHeader(
                    title: "Connectors Platform",
                    subtext: "Federated API bridges with secure auth and mapping.",
                    isCentered: true
                )

                SDKModernCard {
                    HStack(spacing: 0) {
                        statView(label: "Total", value: "\(manager.connectors.count)", color: .accentColor)
                        Divider().padding(.vertical, 4)
                        statView(label: "Active", value: "\(manager.connectors.filter({$0.status == .active}).count)", color: .green)
                        Divider().padding(.vertical, 4)
                        statView(label: "Errors", value: "\(manager.connectors.filter({$0.status == .error}).count)", color: .red)
                    }
                }

                HStack(spacing: 12) {
                    quickButton(title: "New", icon: "plus.circle.fill", color: .blue) { showingBuilder = true }
                    quickButton(title: "Sync", icon: "arrow.triangle.2.circlepath", color: .orange) { Task { try? await sdkManager.syncAll() } }
                    quickButton(title: "Docs", icon: "book.fill", color: .purple) { showingDocs = true }
                }

                SDKSectionHeader(title: "Configured Connectors", subtext: "API integration modules.")

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ConnectorFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    if filteredConnectors.isEmpty {
                        SDKModernCard { Text("No connectors found").sdkSubtext().frame(maxWidth: .infinity) }
                    } else {
                        ForEach(filteredConnectors) { connector in
                            NavigationLink {
                                ConnectorDefinitionDetailView(connector: connector)
                            } label: {
                                connectorRow(connector)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SDKSectionHeader(title: "Platform Tools", subtext: "Global configuration and logs.")
                SDKModernCard {
                    VStack(spacing: 0) {
                        NavigationLink(destination: ConnectorLogsView()) {
                            managementRow(title: "Execution Logs", icon: "list.bullet.rectangle", subtitle: "Global history")
                        }
                        Divider().padding(.vertical, 12)
                        NavigationLink(destination: ConnectorSecurityView()) {
                            managementRow(title: "Security & Scopes", icon: "shield.lefthalf.filled", subtitle: "Access policies")
                        }
                        Divider().padding(.vertical, 12)
                        NavigationLink(destination: SDKConnectorsView()) {
                            managementRow(title: "SDK Connectors", icon: "cable.connector", subtitle: "Kernel bridges")
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Connectors")
        .searchable(text: $searchText, prompt: "Search...")
        .sheet(isPresented: $showingBuilder) {
            NavigationStack { ConnectorBuilderView() }
        }
        .sheet(isPresented: $showingDocs) {
            ConnectorDocumentationView()
        }
    }

    private func connectorRow(_ connector: ConnectorDefinition) -> some View {
        SDKModernCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(connector.name).font(.subheadline.bold())
                    Text(connector.identifier).sdkSubtext()
                }
                Spacer()
                SDKStatusPill(status: connector.status.toSDKStatus(), text: connector.status.rawValue.uppercased())
            }
        }
    }

    private func statView(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func quickButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SDKModernCard {
                HStack(spacing: 8) {
                    Image(systemName: icon).foregroundStyle(color)
                    Text(title).font(.caption.bold())
                }
            }
        }
        .buttonStyle(.plain)
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
    }
}

// RESTORED DELETED STRUCTS
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
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(connector.name).font(.title3.bold())
                        Text(connector.identifier).sdkSubtext()
                    }
                    Spacer()
                    SDKStatusPill(status: connector.status.toSDKStatus(), text: connector.status.rawValue.uppercased())
                }
                LabeledContent("Version", value: "v\(connector.version)")
                if connector.metadata.executionCount > 0 {
                    LabeledContent("Executions", value: "\(connector.metadata.executionCount)")
                }
            } header: { Text("Status & Health") }

            Section {
                Button { Task { await runtime.run(connector: connector) } } label: {
                    Label(isRunning ? "Running..." : "Execute Pipeline", systemImage: isRunning ? "arrow.triangle.2.circlepath" : "play.fill")
                }.disabled(isRunning)
                Button { showingTestConsole = true } label: { Label("Open Test Console", systemImage: "terminal") }
            } header: { Text("Quick Actions") }

            Section {
                ForEach(connector.endpoints) { endpoint in
                    HStack {
                        Text(endpoint.method).font(.caption2.bold()).padding(4).background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                        Text(endpoint.path).font(.system(.caption, design: .monospaced))
                    }
                }
            } header: { Text("Endpoints (\(connector.endpoints.count))") }

            Section {
                NavigationLink(destination: ConnectorBuilderView(connector: connector)) { Label("Edit Identity", systemImage: "pencil.circle") }
                NavigationLink(destination: ConnectorFlowBuilderView(connector: connector)) { Label("Flow Builder", systemImage: "arrow.triangle.branch") }
                NavigationLink(destination: ConnectorSecurityView(connector: connector)) { Label("Security & Scopes", systemImage: "shield.lefthalf.filled") }
            } header: { Text("Configuration") }
        }
        .navigationTitle(connector.name)
        .toolbar {
            Button { showingEditSheet = true } label: { Image(systemName: "pencil.circle") }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack { ConnectorBuilderView(connector: connector) }
        }
        .sheet(isPresented: $showingTestConsole) {
            NavigationStack { ConnectorTestConsoleView(connector: connector) }
        }
    }
}

struct ConnectorDocumentationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    var body: some View {
        NavigationStack {
            List {
                Picker("Section", selection: $selectedTab) {
                    Text("Overview").tag(0); Text("Auth").tag(1); Text("Flows").tag(2)
                }.pickerStyle(.segmented)

                Section {
                    Text("Connectors bridge ToolsKit with external REST APIs. Support for complex auth and workflows.").sdkSubtext()
                }
            }
            .navigationTitle("Documentation")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
