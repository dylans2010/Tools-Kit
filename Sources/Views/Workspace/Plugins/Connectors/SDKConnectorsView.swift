import SwiftUI

struct SDKConnectorsView: View {
    @StateObject private var manager = SDKConnectorManager.shared
    @State private var showingAddSheet = false

    var body: some View {
        List {
            ForEach(manager.connectors, id: \.id) { connector in
                NavigationLink(value: connector.id) {
                    HStack {
                        Image(systemName: icon(for: connector.type))
                            .foregroundStyle(.blue)
                            .frame(width: 30)

                        VStack(alignment: .leading) {
                            Text(connector.name)
                                .font(.headline)
                            Text(connector.type.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        statusBadge(connector.status)
                    }
                }
            }
            .onDelete(perform: deleteConnectors)
        }
        .navigationTitle("Connectors")
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
        offsets.forEach { index in
            let id = manager.connectors[index].id
            manager.remove(id: id)
        }
    }
}

struct AddConnectorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: ConnectorType = .gmail

    var body: some View {
        NavigationStack {
            Form {
                Picker("Connector Type", selection: $selectedType) {
                    ForEach(ConnectorType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }

                Section {
                    Button("Create Connector") {
                        createConnector()
                        dismiss()
                    }
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
