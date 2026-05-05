import SwiftUI

struct ConnectorBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = ConnectorManager.shared

    // Identity
    @State private var name = ""
    @State private var identifier = ""
    @State private var version = "1.0.0"
    @State private var description = ""
    @State private var isIdentifierLocked = false
    @State private var connectorID: UUID?

    // Initializer for editing
    init(connector: ConnectorDefinition? = nil) {
        if let connector = connector {
            _name = State(initialValue: connector.name)
            _identifier = State(initialValue: connector.identifier.replacingOccurrences(of: "com.toolskit.", with: ""))
            _version = State(initialValue: connector.version)
            _description = State(initialValue: connector.description)
            _isIdentifierLocked = State(initialValue: true)
            _connectorID = State(initialValue: connector.id)
        }
    }

    var body: some View {
        Form {
            Section("Connector Identity") {
                TextField("Name", text: $name)

                HStack {
                    Text("Identifier")
                    Spacer()
                    if isIdentifierLocked {
                        Text("com.toolskit.\(identifier)")
                            .foregroundColor(.secondary)
                    } else {
                        Text("com.toolskit.")
                            .foregroundColor(.secondary)
                        TextField("myconnector", text: $identifier)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }

                TextField("Version", text: $version)

                VStack(alignment: .leading) {
                    Text("Description").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }
            } footer: {
                if !isIdentifierLocked {
                    Text("The identifier 'com.toolskit.\(identifier)' will be locked after creation.")
                }
            }

            Section("Capabilities") {
                Text("This connector will act as an integration engine for REST APIs and automated flows.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button(action: saveConnector) {
                    Text(connectorID == nil ? "Create Connector" : "Save Changes")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .disabled(name.isEmpty || identifier.isEmpty)
            }
        }
        .navigationTitle(connectorID == nil ? "New Connector" : "Edit Identity")
        .toolbar {
            if connectorID == nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveConnector() {
        if let id = connectorID {
            if var connector = manager.connectors.first(where: { $0.id == id }) {
                connector.name = name
                connector.version = version
                connector.description = description
                connector.updatedAt = Date()
                manager.updateConnector(connector)
            }
        } else {
            let newConnector = ConnectorDefinition(
                id: UUID(),
                name: name,
                identifier: "com.toolskit.\(identifier)",
                version: version,
                description: description,
                authConfig: ConnectorAuthConfig(type: .none),
                schema: ConnectorSchema(mappings: [:], jsonSchema: "{}"),
                flow: ConnectorFlow(steps: [])
            )
            manager.addConnector(newConnector)
        }
        dismiss()
    }
}
