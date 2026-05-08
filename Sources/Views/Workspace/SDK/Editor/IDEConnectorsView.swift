import SwiftUI

struct IDEConnectorsView: View {
    @StateObject private var manager = SDKConnectorManager.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var searchText = ""
    @State private var showingAddSheet = false

    var filteredConnectors: [any BaseConnector] {
        if searchText.isEmpty {
            return manager.connectors
        }
        return manager.connectors.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Service Connectors").font(.headline)
                            Text("Federated external API integrations and data bridges.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SDKStatusPill("\(manager.connectors.filter { $0.status == .connected }.count)/\(manager.connectors.count)", systemImage: "link", color: .blue)
                    }

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Search connectors...", text: $searchText)
                            .font(.subheadline)
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Connectors", subtitle: "External integration registry", systemImage: "puzzlepiece.extension.fill")
            }

            Section {
                if filteredConnectors.isEmpty {
                    ContentUnavailableView("No Connectors", systemImage: "link.badge.plus", description: Text("Add a connector to bridge external data into the SDK."))
                        .padding(.vertical, 20)
                } else {
                    ForEach(filteredConnectors, id: \.id) { connector in
                        connectorRow(connector)
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { filteredConnectors[$0].id }
                        ids.forEach { manager.remove(id: $0) }
                    }
                }

                Button {
                    showingAddSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Connector")
                    }
                    .font(.subheadline.semibold())
                    .foregroundStyle(.accent)
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Active Bridges", subtitle: "Managed external services", alignment: .leading)
            }
        }
        .navigationTitle("Connectors")
        .sheet(isPresented: $showingAddSheet) {
            AddConnectorView()
        }
    }

    private func connectorRow(_ connector: any BaseConnector) -> some View {
        SDKModernCard(padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon(for: connector.type))
                    .font(.title3)
                    .foregroundStyle(connector.status == .connected ? .blue : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(connector.name).font(.subheadline.bold())
                    Text(connector.type.rawValue.capitalized).font(.system(size: 9, weight: .bold)).foregroundStyle(.tertiary).textCase(.uppercase)
                }

                Spacer()

                SDKStatusPill(
                    connector.status.rawValue,
                    systemImage: connector.status == .connected ? "checkmark.circle.fill" : "xmark.circle.fill",
                    color: connector.status == .connected ? .green : .secondary
                )
            }
        }
        .padding(.vertical, 4)
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
}
