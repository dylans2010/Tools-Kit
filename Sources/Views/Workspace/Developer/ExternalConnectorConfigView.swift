import SwiftUI

struct ExternalConnectorConfigView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAdd = false
    @State private var name = ""
    @State private var type = "REST"
    @State private var baseURL = "https://"

    var body: some View {
        List {
            Section {
                Button(action: { showingAdd = true }) {
                    Label("Register New Connector", systemImage: "link.badge.plus")
                }
            }

            Section("Configured Services") {
                if store.connectors.isEmpty {
                    Text("No connectors configured.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.connectors) { connector in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(connector.name).font(.subheadline.bold())
                                Spacer()
                                Text(connector.type).font(.caption2.bold()).foregroundStyle(.blue)
                            }
                            Text(connector.baseURL).font(.caption).foregroundStyle(.secondary)

                            HStack {
                                Label(connector.isEnabled ? "Enabled" : "Disabled", systemImage: connector.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(connector.isEnabled ? .green : .red)
                                Spacer()
                                Button("Edit") {}
                            }
                            .font(.caption2)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteConnector)
                }
            }
        }
        .navigationTitle("External Connectors")
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form {
                    Section("Service Identity") {
                        TextField("Name (e.g. Stripe, AWS)", text: $name)
                        Picker("Type", selection: $type) {
                            ForEach(["REST", "GraphQL", "Websocket", "gRPC"], id: \.self) { Text($0) }
                        }
                    }
                    Section("Endpoint") {
                        TextField("Base URL", text: $baseURL)
                    }
                }
                .navigationTitle("New Connector")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Register") { saveConnector() }
                            .disabled(name.isEmpty || baseURL.isEmpty)
                    }
                }
            }
        }
    }

    private func saveConnector() {
        let new = ConnectorConfig(name: name, type: type, baseURL: baseURL)
        var updated = store.connectors
        updated.append(new)
        store.saveConnectors(updated)

        name = ""
        baseURL = "https://"
        showingAdd = false
    }

    private func deleteConnector(at offsets: IndexSet) {
        var updated = store.connectors
        updated.remove(atOffsets: offsets)
        store.saveConnectors(updated)
    }
}
