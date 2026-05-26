import SwiftUI

struct ConnectorSchemaMapperView: View {
    @StateObject private var connectorManager = SDKConnectorManager.shared
    @State private var sourceConnector: UUID?
    @State private var targetConnector: UUID?
    @State private var mappings: [MappingRule] = []

    struct MappingRule: Identifiable {
        let id = UUID()
        var sourceField: String
        var targetField: String
        var transformation: String = "None"
    }

    var body: some View {
        List {
            Section("Connector Selection") {
                Picker("Source", selection: $sourceConnector) {
                    Text("Select Source").tag(Optional<UUID>.none)
                    ForEach(connectorManager.connectors, id: \.id) { conn in
                        Text(conn.name).tag(Optional(conn.id))
                    }
                }
                Picker("Target", selection: $targetConnector) {
                    Text("Select Target").tag(Optional<UUID>.none)
                    ForEach(connectorManager.connectors, id: \.id) { conn in
                        Text(conn.name).tag(Optional(conn.id))
                    }
                }
            }

            if sourceConnector != nil && targetConnector != nil {
                Section("Field Mappings") {
                    ForEach($mappings) { $mapping in
                        HStack {
                            TextField("Source Field", text: $mapping.sourceField)
                                .font(.caption.monospaced())
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.secondary)
                            TextField("Target Field", text: $mapping.targetField)
                                .font(.caption.monospaced())
                        }
                    }
                    .onDelete { mappings.remove(atOffsets: $0) }

                    Button(action: { mappings.append(MappingRule(sourceField: "new_field", targetField: "target_field")) }) {
                        Label("Add Mapping", systemImage: "plus")
                    }
                }

                Section {
                    Button(action: saveMapping) {
                        Text("Save Schema Map")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Schema Mapper")
    }

    private func saveMapping() {
        SDKLogStore.shared.log("Saved schema mapping between selected connectors", source: "SchemaMapper", level: .info)
    }
}
