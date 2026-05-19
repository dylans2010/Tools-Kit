import SwiftUI

struct ConnectorsMainView: View {
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var toolManager = SDKToolManager.shared
    @State private var searchText = ""
    @State private var filterCategory: ConnectorCategory = .all

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
        Section(header: Text("Overview")) {
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
                        Label(tool.name, systemImage: tool.icon ?? "wrench")
                            .font(.subheadline)
                        Spacer()
                        Text(tool.isEnabled ? "Active" : "Inactive")
                            .font(.caption2)
                            .foregroundStyle(tool.isEnabled ? Color.green : Color.secondary)
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
        .navigationDestination(for: UUID.self) { id in
            if let connector = connectorManager.connectors.first(where: { $0.id == id }) {
                ConnectorDetailView(connector: connector)
            }
        }
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
