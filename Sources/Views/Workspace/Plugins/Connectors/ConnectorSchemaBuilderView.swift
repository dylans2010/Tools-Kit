import SwiftUI

struct ConnectorSchemaBuilderView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared

    @State private var jsonSchema: String
    @State private var mappings: [MappingEntry]

    struct MappingEntry: Identifiable {
        let id = UUID()
        var source: String
        var target: String
    }

    init(connector: ConnectorDefinition) {
        self.connector = connector
        _jsonSchema = State(initialValue: connector.schema.jsonSchema)

        let initialMappings = connector.schema.mappings.map { MappingEntry(source: $0.key, target: $0.value) }
        _mappings = State(initialValue: initialMappings.isEmpty ? [MappingEntry(source: "", target: "")] : initialMappings)
    }

    var body: some View {
        Form {
            Section("JSON Response Schema") {
                VStack(alignment: .leading) {
                    Text("Define the expected API response structure.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $jsonSchema)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 200)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
                .padding(.vertical, 8)
            }

            Section("Data Mapping") {
                Text("Map API fields to Workspace models.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach($mappings) { $entry in
                    HStack {
                        TextField("API Field", text: $entry.source)
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        TextField("Workspace Model", text: $entry.target)
                    }
                }
                .onDelete { indices in
                    mappings.remove(atOffsets: indices)
                }

                Button("Add Mapping") {
                    mappings.append(MappingEntry(source: "", target: ""))
                }
            }

            Section {
                Button("Save Schema & Mappings") {
                    saveSchema()
                }
                .frame(maxWidth: .infinity)
                .bold()
            }
        }
        .navigationTitle("Schema Builder")
    }

    private func saveSchema() {
        var mappingDict: [String: String] = [:]
        for entry in mappings where !entry.source.isEmpty && !entry.target.isEmpty {
            mappingDict[entry.source] = entry.target
        }

        connector.schema = ConnectorSchema(mappings: mappingDict, jsonSchema: jsonSchema)
        manager.updateConnector(connector)
    }
}
