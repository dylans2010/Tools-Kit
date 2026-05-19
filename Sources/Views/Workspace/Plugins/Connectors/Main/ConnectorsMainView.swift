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

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(totalCount)").font(.title3.bold()).foregroundStyle(.blue)
                        Text("Total").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 2) {
                        Text("\(connectedCount)").font(.title3.bold()).foregroundStyle(.green)
                        Text("Connected").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 2) {
                        Text("\(toolManager.tools.count)").font(.title3.bold()).foregroundStyle(.orange)
                        Text("Tools").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Overview")
            }

            Section {
                Picker("Filter", selection: $filterCategory) {
                    ForEach(ConnectorCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Connectors") {
                if filteredConnectors.isEmpty {
                    ContentUnavailableView(
                        "No Connectors Found",
                        systemImage: "cable.connector.slash",
                        description: Text(searchText.isEmpty ? "No connectors registered." : "No matches for \"\(searchText)\".")
                    )
                } else {
                    ForEach(filteredConnectors) { connector in
                        NavigationLink {
                            ConnectorDetailView(connector: connector)
                        } label: {
                            HStack {
                                Image(systemName: connector.isConnected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(connector.isConnected ? .green : .secondary)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(connector.name).font(.subheadline.bold())
                                    Text(connector.isConnected ? "Connected" : "Disconnected")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            if !toolManager.tools.isEmpty {
                Section("Platform Tools") {
                    ForEach(toolManager.tools) { tool in
                        HStack {
                            Label(tool.name, systemImage: tool.icon ?? "wrench")
                            Spacer()
                            Text(tool.isEnabled ? "Active" : "Inactive")
                                .font(.caption2)
                                .foregroundStyle(tool.isEnabled ? .green : .secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Connectors")
        .searchable(text: $searchText, prompt: "Search Connectors")
    }
}

