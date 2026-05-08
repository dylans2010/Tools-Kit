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

    // Auth Configuration
    @State private var selectedAuthType: ConnectorAuthConfig.AuthType = .none
    @State private var apiKeyHeaderName = "X-API-Key"
    @State private var apiKeyValue = ""
    @State private var bearerToken = ""
    @State private var oauthClientID = ""
    @State private var oauthClientSecret = ""
    @State private var oauthAuthURL = ""
    @State private var oauthTokenURL = ""
    @State private var oauthScopes = ""

    // Endpoint Quick-Add
    @State private var baseURL = ""
    @State private var quickEndpointPath = ""
    @State private var quickEndpointMethod = "GET"
    @State private var pendingEndpoints: [ConnectorEndpoint] = []

    // Tags
    @State private var tags = ""

    // Validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var showingPresetConnectors = false

    init(connector: ConnectorDefinition? = nil) {
        if let connector = connector {
            _name = State(initialValue: connector.name)
            _identifier = State(initialValue: connector.identifier.replacingOccurrences(of: "com.toolskit.", with: ""))
            _version = State(initialValue: connector.version)
            _description = State(initialValue: connector.description)
            _isIdentifierLocked = State(initialValue: true)
            _connectorID = State(initialValue: connector.id)
            _selectedAuthType = State(initialValue: connector.authConfig.type)
            _pendingEndpoints = State(initialValue: connector.endpoints)

            if connector.authConfig.type == .apiKey {
                _apiKeyHeaderName = State(initialValue: connector.authConfig.credentials["headerName"] ?? "X-API-Key")
            } else if connector.authConfig.type == .bearer {
                _bearerToken = State(initialValue: connector.authConfig.credentials["token"] ?? "")
            } else if connector.authConfig.type == .oauth2, let oauth = connector.authConfig.oauthConfig {
                _oauthClientID = State(initialValue: oauth.clientID)
                _oauthClientSecret = State(initialValue: oauth.clientSecret)
                _oauthAuthURL = State(initialValue: oauth.authURL)
                _oauthTokenURL = State(initialValue: oauth.tokenURL)
                _oauthScopes = State(initialValue: oauth.scopes.joined(separator: ", "))
            }
        }
    }

    var body: some View {
        Form {
            // MARK: - Identity
            Section {
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

                TextField("Version (e.g. 1.0.0)", text: $version)

                VStack(alignment: .leading) {
                    Text("Description").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }

                TextField("Tags (comma-separated)", text: $tags)
                    .autocapitalization(.none)
            } header: {
                Text("Connector Identity")
            } footer: {
                if !isIdentifierLocked {
                    Text("The identifier 'com.toolskit.\(identifier)' will be locked after creation.")
                }
            }

            // MARK: - Base URL
            Section {
                TextField("https://api.example.com/v1", text: $baseURL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)

                Text("All endpoint paths will be relative to this base URL.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Base URL")
            }

            // MARK: - Authentication
            Section {
                Picker("Auth Type", selection: $selectedAuthType) {
                    Text("None").tag(ConnectorAuthConfig.AuthType.none)
                    Text("API Key").tag(ConnectorAuthConfig.AuthType.apiKey)
                    Text("Bearer Token").tag(ConnectorAuthConfig.AuthType.bearer)
                    Text("OAuth 2.0").tag(ConnectorAuthConfig.AuthType.oauth2)
                }

                switch selectedAuthType {
                case .apiKey:
                    TextField("Header Name", text: $apiKeyHeaderName)
                        .autocapitalization(.none)
                    SecureField("API Key Value", text: $apiKeyValue)
                case .bearer:
                    SecureField("Bearer Token", text: $bearerToken)
                case .oauth2:
                    TextField("Client ID", text: $oauthClientID)
                        .autocapitalization(.none)
                    SecureField("Client Secret", text: $oauthClientSecret)
                    TextField("Authorization URL", text: $oauthAuthURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    TextField("Token URL", text: $oauthTokenURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    TextField("Scopes (comma-separated)", text: $oauthScopes)
                        .autocapitalization(.none)
                case .none:
                    Text("No authentication will be applied to requests.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Authentication")
            }

            // MARK: - Endpoints
            Section {
                if !pendingEndpoints.isEmpty {
                    ForEach(pendingEndpoints) { endpoint in
                        HStack {
                            Text(endpoint.method)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(endpointMethodColor(endpoint.method).opacity(0.15))
                                .foregroundColor(endpointMethodColor(endpoint.method))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text(endpoint.path)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                        }
                    }
                    .onDelete { indices in
                        pendingEndpoints.remove(atOffsets: indices)
                    }
                }

                HStack {
                    Picker("", selection: $quickEndpointMethod) {
                        ForEach(["GET", "POST", "PUT", "DELETE", "PATCH"], id: \.self) { m in
                            Text(m).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 90)

                    TextField("/path", text: $quickEndpointPath)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))

                    Button {
                        addEndpoint()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(quickEndpointPath.isEmpty)
                }

                if !pendingEndpoints.isEmpty {
                    Text("\(pendingEndpoints.count) endpoint(s) configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Endpoints")
            }

            // MARK: - Capabilities Summary
            Section {
                HStack {
                    Label("REST Integration", systemImage: "network")
                        .font(.caption)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                HStack {
                    Label("Automated Flows", systemImage: "arrow.triangle.branch")
                        .font(.caption)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                HStack {
                    Label("Schema Mapping", systemImage: "doc.text.magnifyingglass")
                        .font(.caption)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                HStack {
                    Label("Secure Auth", systemImage: "lock.shield")
                        .font(.caption)
                    Spacer()
                    Image(systemName: selectedAuthType != .none ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedAuthType != .none ? .green : .secondary)
                        .font(.caption)
                }
            } header: {
                Text("Capabilities")
            }

            Section {
                LabeledContent("Connectors", value: "\(manager.connectors.count)")
                LabeledContent("Activity Logs", value: "\(manager.logs.count)")
                if let existing = connectorID.flatMap({ id in manager.connectors.first(where: { $0.id == id }) }) {
                    LabeledContent("Executions", value: "\(existing.metadata.executionCount)")
                    LabeledContent("Average Latency", value: "\(existing.metadata.averageLatency, specifier: "%.0f") ms")
                    LabeledContent("Error Rate", value: "\(existing.metadata.errorRate, specifier: "%.1f")%")
                }
                if let lastLog = manager.logs.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Latest user activity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(lastLog.message)
                            .font(.caption)
                    }
                }
            } header: {
                Text("Saved Connector Data")
            }

            // MARK: - Save
            Section {
                Button(action: validateAndSave) {
                    Text(connectorID == nil ? "Create Connector" : "Save Changes")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .disabled(name.isEmpty || identifier.isEmpty)
            }
        }
        .navigationTitle(connectorID == nil ? "New Connector" : "Edit Connector")
        .toolbar {
            if connectorID == nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingPresetConnectors = true
                } label: {
                    Label("Add Preset", systemImage: "square.grid.2x2")
                }
            }
        }
        .sheet(isPresented: $showingPresetConnectors) {
            PresetConnectorsView()
        }
        .alert("Validation", isPresented: $showingValidationAlert) {
            Button("OK") {}
        } message: {
            Text(validationMessage)
        }
    }

    private func addEndpoint() {
        let fullPath: String
        if !baseURL.isEmpty && !quickEndpointPath.hasPrefix("http") {
            fullPath = baseURL.hasSuffix("/") ? "\(baseURL)\(quickEndpointPath)" : "\(baseURL)\(quickEndpointPath)"
        } else {
            fullPath = quickEndpointPath
        }

        let endpoint = ConnectorEndpoint(
            path: fullPath,
            method: quickEndpointMethod,
            headers: [:],
            queryParams: [:]
        )
        pendingEndpoints.append(endpoint)
        quickEndpointPath = ""
    }

    private func endpointMethodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .secondary
        }
    }

    private func buildAuthConfig() -> ConnectorAuthConfig {
        switch selectedAuthType {
        case .apiKey:
            return ConnectorAuthConfig(
                type: .apiKey,
                credentials: ["headerName": apiKeyHeaderName, "apiKey": apiKeyValue]
            )
        case .bearer:
            return ConnectorAuthConfig(
                type: .bearer,
                credentials: ["token": bearerToken]
            )
        case .oauth2:
            let scopes = oauthScopes.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            return ConnectorAuthConfig(
                type: .oauth2,
                credentials: [:],
                oauthConfig: OAuthConfig(
                    clientID: oauthClientID,
                    clientSecret: oauthClientSecret,
                    authURL: oauthAuthURL,
                    tokenURL: oauthTokenURL,
                    scopes: scopes
                )
            )
        case .none:
            return ConnectorAuthConfig(type: .none)
        }
    }

    private func validateAndSave() {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Connector name cannot be empty."
            showingValidationAlert = true
            return
        }

        if identifier.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Connector identifier cannot be empty."
            showingValidationAlert = true
            return
        }

        if selectedAuthType == .oauth2 && (oauthClientID.isEmpty || oauthAuthURL.isEmpty || oauthTokenURL.isEmpty) {
            validationMessage = "OAuth2 requires Client ID, Auth URL, and Token URL."
            showingValidationAlert = true
            return
        }

        saveConnector()
    }

    private func saveConnector() {
        let authConfig = buildAuthConfig()

        if let id = connectorID {
            if var connector = manager.connectors.first(where: { $0.id == id }) {
                connector.name = name
                connector.version = version
                connector.description = description
                connector.authConfig = authConfig
                connector.endpoints = pendingEndpoints
                connector.updatedAt = Date()
                manager.updateConnector(connector)
                manager.addLog(ConnectorLog(connectorID: connector.id, timestamp: Date(), type: .info, message: "Connector updated", details: "Version \(connector.version) with \(connector.endpoints.count) endpoint(s)"))
            }
        } else {
            let newConnector = ConnectorDefinition(
                id: UUID(),
                name: name,
                identifier: "com.toolskit.\(identifier)",
                version: version,
                description: description,
                authConfig: authConfig,
                schema: ConnectorSchema(mappings: [:], jsonSchema: "{}"),
                flow: ConnectorFlow(steps: [])
            )
            var mutableConnector = newConnector
            mutableConnector.endpoints = pendingEndpoints
            manager.addConnector(mutableConnector)
            manager.addLog(ConnectorLog(connectorID: mutableConnector.id, timestamp: Date(), type: .info, message: "Connector created", details: "\(mutableConnector.endpoints.count) endpoint(s) configured"))
        }
        dismiss()
    }
}
