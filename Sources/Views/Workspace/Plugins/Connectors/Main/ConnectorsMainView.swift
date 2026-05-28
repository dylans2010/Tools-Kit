import SwiftUI

struct ConnectorsMainView: View {
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var toolManager = SDKToolManager.shared
    @State private var searchText = ""
    @State private var filterCategory: ConnectorCategory = .all
    @State private var showingConnectorBuilder = false
    @State private var showingInstaller = false

    enum ConnectorCategory: String, CaseIterable {
        case all = "All"
        case connected = "Connected"
        case disconnected = "Disconnected"
    }

    private var filteredConnectors: [any BaseConnector] {
        var results = connectorManager.connectors
        if !searchText.isEmpty {
            results = results.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch filterCategory {
        case .all: break
        case .connected: results = results.filter(\.isConnected)
        case .disconnected: results = results.filter { !$0.isConnected }
        }
        return results
    }

    private var connectedCount: Int { connectorManager.connectors.filter(\.isConnected).count }
    private var totalCount: Int { connectorManager.connectors.count }

    @ViewBuilder
    private var overviewSection: some View {
        Section(header: Text("Intelligent Management")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NavigationLink(destination: ConnectorTrafficAnalyzerView()) {
                        QuickToolCard(title: "Traffic", icon: "waveform.path.ecg", color: .blue)
                    }
                    NavigationLink(destination: ConnectorSchemaMapperView()) {
                        QuickToolCard(title: "Mapping", icon: "arrow.triangle.merge", color: .purple)
                    }
                    NavigationLink(destination: ConnectorAuthStatusDashboardView()) {
                        QuickToolCard(title: "Auth", icon: "key.fill", color: .green)
                    }
                    NavigationLink(destination: ConnectorRetryPolicyEditorView()) {
                        QuickToolCard(title: "Retry", icon: "arrow.clockwise.circle", color: .orange)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(totalCount)")
                        .font(.title3.bold())
                        .foregroundStyle(Color.blue)
                    Text("Total")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("\(connectedCount)")
                        .font(.title3.bold())
                        .foregroundStyle(Color.green)
                    Text("Connected")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("\(toolManager.tools.count)")
                        .font(.title3.bold())
                        .foregroundStyle(Color.orange)
                    Text("Tools")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var filterSection: some View {
        Section(header: Text("Filter")) {
            Picker("Filter", selection: $filterCategory) {
                ForEach(ConnectorCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var connectorsSection: some View {
        Section(header: Text("Connectors")) {
            if filteredConnectors.isEmpty {
                ContentUnavailableView(
                    "No Connectors Found",
                    systemImage: "cable.connector.slash",
                    description: Text(searchText.isEmpty ? "No connectors registered." : "No matches for \"\(searchText)\".")
                )
            } else {
                ForEach(filteredConnectors, id: \.id) { connector in
                    NavigationLink(value: connector.id) {
                        ConnectorRow(connector: connector)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var platformToolsSection: some View {
        if !toolManager.tools.isEmpty {
            Section(header: Text("Platform Tools")) {
                ForEach(toolManager.tools, id: \.id) { tool in
                    HStack(alignment: .top, spacing: 12) {
                        Label(tool.name, systemImage: "wrench")
                            .font(.subheadline)
                        Spacer()
                        Text(tool.category.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    var body: some View {
        List {
            overviewSection
            filterSection
            connectorsSection
            platformToolsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Connectors")
        .searchable(text: $searchText, prompt: "Search Connectors")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showingInstaller = true
                    } label: {
                        Image(systemName: "plus.app")
                    }
                    Button {
                        showingConnectorBuilder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingConnectorBuilder) {
            NavigationStack {
                ConnectorBuilderView()
            }
        }
        .sheet(isPresented: $showingInstaller) {
            ProjectInstallerView()
                .presentationDetents([.medium])
        }
        .navigationDestination(for: UUID.self) { id in
            if let connector = connectorManager.connectors.first(where: { $0.id == id }) {
                Self.openDetailView(connector)
            }
        }
    }
    private static func openDetailView(_ connector: any BaseConnector) -> AnyView {
        func open<C: BaseConnector>(_ c: C) -> AnyView {
            AnyView(ConnectorDetailView(connector: c))
        }
        return open(connector)
    }
}

private struct QuickToolCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.primary)
        }
        .frame(width: 70)
    }
}

private struct ConnectorRow: View {
    let connector: any BaseConnector

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: connector.isConnected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(connector.isConnected ? Color.green : Color.secondary)
                .font(.caption)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(connector.name)
                    .font(.subheadline.bold())
                Text(connector.isConnected ? "Connected" : "Disconnected")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
