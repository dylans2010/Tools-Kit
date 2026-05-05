import SwiftUI

struct ConnectorDetailView: View {
    let connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(connector.name).font(.title2.bold())
                        Spacer()
                        StatusPill(status: connector.status)
                    }
                    Text(connector.description).font(.body).foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Status") {
                Toggle("Enabled", isOn: Binding(
                    get: { connector.isEnabled },
                    set: { _ in manager.toggleConnector(id: connector.id) }
                ))
            }

            Section("Tools") {
                NavigationLink(destination: ConnectorExecutionView(connector: connector)) {
                    Label("Run Pipeline", systemImage: "play.fill")
                }
                NavigationLink(destination: ConnectorTestConsoleView(connector: connector)) {
                    Label("Test Console", systemImage: "terminal")
                }
                NavigationLink(destination: ConnectorSecurityView(connector: connector)) {
                    Label("Security & Scopes", systemImage: "shield")
                }
                NavigationLink(destination: ConnectorVersioningView(connector: connector)) {
                    Label("Versioning", systemImage: "clock")
                }
            }
        }
        .navigationTitle("Connector Detail")
    }
}
