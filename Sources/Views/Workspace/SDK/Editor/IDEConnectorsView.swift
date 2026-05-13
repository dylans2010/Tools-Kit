import SwiftUI

struct IDEConnectorsView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @State private var selectedConnectorID: UUID?

    var body: some View {
        List {
            Section("Integration Summary") {
                LabeledContent("Registered", value: "\(connectorManager.connectors.count)")
                LabeledContent("Connected", value: "\(connectorManager.connectors.filter { $0.status == .connected }.count)")
                LabeledContent("Dependency Links", value: "\(connectorLinkedDependencyCount)")
            }

            Section("Connector Registry") {
                if connectorManager.connectors.isEmpty {
                    ContentUnavailableView(
                        "No Connectors",
                        systemImage: "link",
                        description: Text("Connectors registered in the SDK connector workspace will appear here.")
                    )
                } else {
                    ForEach(connectorManager.connectors, id: \.id) { connector in
                        ConnectorRegistryRow(
                            connector: connector,
                            linkedDependencyNames: linkedDependencyNames(for: connector),
                            isSelected: selectedConnectorID == connector.id,
                            isAuthorized: authorizationManager.canUseConnector(id: connector.id)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { selectedConnectorID = connector.id }
                    }
                }
            }

            if let selectedConnector = connectorManager.connectors.first(where: { $0.id == selectedConnectorID }) {
                Section("Selection") {
                    LabeledContent("Name", value: selectedConnector.name)
                    LabeledContent("Type", value: selectedConnector.type.rawValue.capitalized)
                    LabeledContent("Status", value: selectedConnector.status.rawValue.capitalized)
                    LabeledContent("Activity Events", value: "\(selectedConnector.activityLog.count)")
                }
            }
        }
        .navigationTitle("Connectors")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var connectorLinkedDependencyCount: Int {
        let connectorNodes = state.dependencies.filter { $0.kind == .connector }
        return connectorNodes.reduce(0) { $0 + $1.linkedTo.count }
    }

    private func linkedDependencyNames(for connector: any BaseConnector) -> [String] {
        state.dependencies
            .filter { $0.kind == .connector && $0.name.localizedCaseInsensitiveContains(connector.name) }
            .map(\.name)
    }
}

private struct ConnectorRegistryRow: View {
    let connector: any BaseConnector
    let linkedDependencyNames: [String]
    let isSelected: Bool
    let isAuthorized: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(connector.name, systemImage: symbol)
                    .font(.headline)
                Spacer()
                Text(connector.status.rawValue.capitalized)
                    .font(.caption)
            }

            Text("Type: \(connector.type.rawValue.capitalized)")
                .font(.caption)

                Text("Module Links: \(linkedDependencyNames.isEmpty ? "None" : linkedDependencyNames.joined(separator: ", "))")
                    .font(.caption2)
                if !isAuthorized {
                    Text("Blocked by authorization")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
        }
        .padding(.vertical, 4)
        .overlay(alignment: .leading) {
            if isSelected {
                Rectangle().frame(width: 2)
            }
        }
    }

    private var symbol: String {
        switch connector.type {
        case .github:
            return "terminal"
        case .gmail:
            return "envelope"
        case .webhook:
            return "network"
        case .localFileSystem:
            return "folder"
        case .calendar:
            return "calendar"
        case .rest:
            return "globe"
        case .mqtt:
            return "antenna.radiowaves.left.and.right"
        }
    }
}
