import SwiftUI

struct ConnectorBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = ConnectorManager.shared

    @State private var name = ""
    @State private var identifier = ""
    @State private var description = ""
    @State private var author = "Developer"
    @State private var version = "1.0.0"

    @State private var endpoints: [ExternalAPIEndpoint] = []
    @State private var auth = ConnectorAuth()
    @State private var flows: [ConnectorFlow] = []

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Name", text: $name)
                TextField("Identifier", text: $identifier)
                TextField("Description", text: $description)
                TextField("Author", text: $author)
                TextField("Version", text: $version)
            }

            Section("Components") {
                NavigationLink(destination: ConnectorAuthView(auth: $auth)) {
                    Label("Authentication", systemImage: "key")
                }
                NavigationLink(destination: ConnectorSchemaBuilderView()) {
                    Label("Data Mapping", systemImage: "arrow.left.arrow.right")
                }
                NavigationLink(destination: ConnectorFlowBuilderView(flows: $flows)) {
                    Label("Flow Builder", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section("Endpoints") {
                ForEach(endpoints) { endpoint in
                    HStack {
                        Text(endpoint.name)
                        Spacer()
                        Text(endpoint.method.rawValue).font(.caption).secondary()
                    }
                }
                Button("Add Endpoint") {
                    endpoints.append(ExternalAPIEndpoint(name: "New Endpoint", baseURL: "", path: "", method: .get, headers: [:], queryParams: [:], authType: .none, retryPolicy: RetryPolicy()))
                }
            }

            Section {
                Button("Save Connector") {
                    let connector = ConnectorDefinition(
                        id: UUID(),
                        name: name,
                        identifier: "com.toolskit.connector.\(identifier)",
                        version: version,
                        description: description,
                        author: author,
                        endpoints: endpoints,
                        auth: auth,
                        flows: flows,
                        dataMappings: []
                    )
                    manager.saveConnector(connector)
                    dismiss()
                }
                .disabled(name.isEmpty || identifier.isEmpty)
            }
        }
        .navigationTitle("Connector Builder")
    }
}
