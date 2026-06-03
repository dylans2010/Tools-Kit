import SwiftUI

struct ConnectorAuthRegistryView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAddAuth = false

    var body: some View {
        List {
            Section("Active Credentials") {
                if store.connectorAuths.isEmpty {
                    EmptyStateView(icon: "link.circle", title: "No Connectors", message: "Register your first connector.")
                } else {
                    ForEach(store.connectorAuths) { connector in
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundStyle(connector.status == "Authorized" ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(connector.service).font(.subheadline.bold())
                                Text(connector.account).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(connector.status)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(connector.status == "Authorized" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .foregroundStyle(connector.status == "Authorized" ? .green : .red)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Section {
                Button { showingAddAuth = true } label: {
                    Label("Register New Connector", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Connector Auth")
        .alert("New Connector", isPresented: $showingAddAuth) {
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                var current = store.connectorAuths
                current.append(ConnectorAuth(service: "Slack", account: "workspace-alerts", status: "Authorized"))
                store.saveConnectorAuths(current)
            }
        }
    }
}
