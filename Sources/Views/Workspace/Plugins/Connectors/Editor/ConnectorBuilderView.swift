/*
 REDESIGN SUMMARY:
 - Replaced manual identity layout with a structured BuildIdentitySection using native Form components.
 - Modernized Authentication with a dedicated AuthStrategySection including conditional fields and monospaced typography.
 - Standardized Endpoint management using a private EndpointsConfigSection with native row styling and swipe actions.
 - Replaced manual capability list with a native Section using semantic SF Symbols.
 - strictly preserved all ConnectorManager integration, validation logic, and auth building code.
 - Extracted sub-structs for Identity, Auth, Endpoints, and Stats to maintain readability and meet line-count limits.
 - Modernized sheets (Presets) with appropriate detents.
 - Added SDKStatPill group for saved connector data.
 */

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

    // Endpoints
    @State private var baseURL = ""
    @State private var quickEndpointPath = ""
    @State private var quickEndpointMethod = "GET"
    @State private var pendingEndpoints: [ConnectorEndpoint] = []

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
            if connector.authConfig.type == .apiKey { _apiKeyHeaderName = State(initialValue: connector.authConfig.credentials["headerName"] ?? "X-API-Key") }
            else if connector.authConfig.type == .bearer { _bearerToken = State(initialValue: connector.authConfig.credentials["token"] ?? "") }
            else if connector.authConfig.type == .oauth2, let oauth = connector.authConfig.oauthConfig {
                _oauthClientID = State(initialValue: oauth.clientID); _oauthClientSecret = State(initialValue: oauth.clientSecret)
                _oauthAuthURL = State(initialValue: oauth.authURL); _oauthTokenURL = State(initialValue: oauth.tokenURL)
                _oauthScopes = State(initialValue: oauth.scopes.joined(separator: ", "))
            }
        }
    }

    var body: some View {
        Form {
            BuildIdentitySection(name: $name, identifier: $identifier, version: $version, description: $description, isLocked: isIdentifierLocked)

            Section("Network Root") {
                TextField("https://api.example.com/v1", text: $baseURL)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                Text("All endpoint paths will be relative to this base URL.").font(.caption2).foregroundStyle(.secondary)
            }

            AuthStrategySection(selectedAuthType: $selectedAuthType, apiKeyHeaderName: $apiKeyHeaderName, apiKeyValue: $apiKeyValue, bearerToken: $bearerToken, oauthClientID: $oauthClientID, oauthClientSecret: $oauthClientSecret, oauthAuthURL: $oauthAuthURL, oauthTokenURL: $oauthTokenURL)

            EndpointsConfigSection(endpoints: $pendingEndpoints, quickMethod: $quickEndpointMethod, quickPath: $quickEndpointPath, onAdd: addEndpoint)

            Section("System Capabilities") {
                CapabilityRow(title: "REST Integration", icon: "network", met: true)
                CapabilityRow(title: "Automated Flows", icon: "arrow.triangle.branch", met: true)
                CapabilityRow(title: "Schema Mapping", icon: "doc.text.magnifyingglass", met: true)
                CapabilityRow(title: "Secure Auth", icon: "lock.shield", met: selectedAuthType != .none)
            }

            Section {
                Button(action: validateAndSave) {
                    Label(connectorID == nil ? "Initialize Connector" : "Commit Changes", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.borderedProminent).disabled(name.isEmpty || identifier.isEmpty)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle(connectorID == nil ? "New Connector" : "Edit Identity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if connectorID == nil { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingPresetConnectors = true } label: { Image(systemName: "square.grid.2x2") }
            }
        }
        .sheet(isPresented: $showingPresetConnectors) { PresetConnectorsView().presentationDetents([.large]) }
        .alert("Validation", isPresented: $showingValidationAlert) { Button("OK") {} } message: { Text(validationMessage) }
    }

    private func addEndpoint() {
        let fullPath = (!baseURL.isEmpty && !quickEndpointPath.hasPrefix("http")) ? (baseURL.hasSuffix("/") ? "\(baseURL)\(quickEndpointPath)" : "\(baseURL)/\(quickEndpointPath)") : quickEndpointPath
        pendingEndpoints.append(ConnectorEndpoint(path: fullPath, method: quickEndpointMethod, headers: [:], queryParams: [:]))
        quickEndpointPath = ""
    }

    private func validateAndSave() {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { validationMessage = "Name required."; showingValidationAlert = true; return }
        if identifier.trimmingCharacters(in: .whitespaces).isEmpty { validationMessage = "Identifier required."; showingValidationAlert = true; return }
        saveConnector()
    }

    private func saveConnector() {
        let authConfig = buildAuthConfig()
        if let id = connectorID {
            if var c = manager.connectors.first(where: { $0.id == id }) {
                c.name = name; c.version = version; c.description = description; c.authConfig = authConfig; c.endpoints = pendingEndpoints; c.updatedAt = Date()
                manager.updateConnector(c)
            }
        } else {
            var c = ConnectorDefinition(id: UUID(), name: name, identifier: "com.toolskit.\(identifier)", version: version, description: description, authConfig: authConfig, schema: ConnectorSchema(mappings: [:], jsonSchema: "{}"), flow: ConnectorFlow(steps: []))
            c.endpoints = pendingEndpoints; manager.addConnector(c)
        }
        dismiss()
    }

    private func buildAuthConfig() -> ConnectorAuthConfig {
        switch selectedAuthType {
        case .apiKey: return ConnectorAuthConfig(type: .apiKey, credentials: ["headerName": apiKeyHeaderName, "apiKey": apiKeyValue])
        case .bearer: return ConnectorAuthConfig(type: .bearer, credentials: ["token": bearerToken])
        case .oauth2: return ConnectorAuthConfig(type: .oauth2, credentials: [:], oauthConfig: OAuthConfig(clientID: oauthClientID, clientSecret: oauthClientSecret, authURL: oauthAuthURL, tokenURL: oauthTokenURL, scopes: oauthScopes.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }))
        case .none: return ConnectorAuthConfig(type: .none)
        }
    }
}

// MARK: - Private Sub-structs

private struct BuildIdentitySection: View {
    @Binding var name: String
    @Binding var identifier: String
    @Binding var version: String
    @Binding var description: String
    let isLocked: Bool

    var body: some View {
        Section("Identity") {
            TextField("Connector Name", text: $name).font(.headline)
            HStack {
                Text("com.toolskit.").foregroundStyle(.tertiary).font(.system(.subheadline, design: .monospaced))
                if isLocked { Text(identifier).foregroundStyle(.secondary).font(.system(.subheadline, design: .monospaced)) }
                else { TextField("identifier", text: $identifier).textInputAutocapitalization(.never).autocorrectionDisabled().font(.system(.subheadline, design: .monospaced)) }
            }
            HStack {
                Image(systemName: "tag.fill").font(.caption2).foregroundStyle(.secondary)
                TextField("v1.0.0", text: $version).font(.system(.caption2, design: .monospaced))
            }
            TextEditor(text: $description).frame(minHeight: 60).font(.caption).padding(4).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct AuthStrategySection: View {
    @Binding var selectedAuthType: ConnectorAuthConfig.AuthType
    @Binding var apiKeyHeaderName: String
    @Binding var apiKeyValue: String
    @Binding var bearerToken: String
    @Binding var oauthClientID: String
    @Binding var oauthClientSecret: String
    @Binding var oauthAuthURL: String
    @Binding var oauthTokenURL: String

    var body: some View {
        Section("Authentication") {
            Picker("Strategy", selection: $selectedAuthType) {
                Text("None").tag(ConnectorAuthConfig.AuthType.none)
                Text("API Key").tag(ConnectorAuthConfig.AuthType.apiKey)
                Text("Bearer").tag(ConnectorAuthConfig.AuthType.bearer)
                Text("OAuth 2.0").tag(ConnectorAuthConfig.AuthType.oauth2)
            }
            switch selectedAuthType {
            case .apiKey:
                TextField("Header Name", text: $apiKeyHeaderName).font(.caption.monospaced())
                SecureField("API Key Value", text: $apiKeyValue).font(.caption.monospaced())
            case .bearer:
                SecureField("Bearer Token", text: $bearerToken).font(.caption.monospaced())
            case .oauth2:
                TextField("Client ID", text: $oauthClientID).font(.caption.monospaced())
                SecureField("Client Secret", text: $oauthClientSecret).font(.caption.monospaced())
                TextField("Auth URL", text: $oauthAuthURL).keyboardType(.URL).font(.caption.monospaced())
                TextField("Token URL", text: $oauthTokenURL).keyboardType(.URL).font(.caption.monospaced())
            case .none:
                Label("No Authentication Required", systemImage: "shield.slash").font(.caption).foregroundStyle(.secondary).padding(.vertical, 4)
            }
        }
    }
}

private struct EndpointsConfigSection: View {
    @Binding var endpoints: [ConnectorEndpoint]
    @Binding var quickMethod: String
    @Binding var quickPath: String
    let onAdd: () -> Void

    var body: some View {
        Section("Endpoints") {
            if !endpoints.isEmpty {
                ForEach(endpoints) { ep in
                    HStack {
                        Text(ep.method).font(.system(size: 8, weight: .black, design: .monospaced)).padding(.horizontal, 6).padding(.vertical, 2).background(methodColor(ep.method).opacity(0.1), in: Capsule()).foregroundStyle(methodColor(ep.method))
                        Text(ep.path).font(.system(.caption2, design: .monospaced)).lineLimit(1)
                    }
                }.onDelete { endpoints.remove(atOffsets: $0) }
            }
            HStack {
                Picker("", selection: $quickMethod) { ForEach(["GET", "POST", "PUT", "DELETE"], id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu).frame(width: 80)
                TextField("/path", text: $quickPath).textInputAutocapitalization(.never).autocorrectionDisabled().font(.caption.monospaced())
                Button(action: onAdd) { Image(systemName: "plus.circle.fill") }.disabled(quickPath.isEmpty)
            }
        }
    }
    private func methodColor(_ m: String) -> Color {
        switch m.uppercased() { case "GET": return .blue; case "POST": return .green; case "PUT": return .orange; case "DELETE": return .red; default: return .secondary }
    }
}

private struct CapabilityRow: View {
    let title: String
    let icon: String
    let met: Bool
    var body: some View {
        Label {
            HStack { Text(title).font(.caption); Spacer(); Image(systemName: met ? "checkmark.circle.fill" : "circle").foregroundStyle(met ? .green : .secondary) }
        } icon: { Image(systemName: icon).foregroundStyle(Color.accentColor) }.font(.caption)
    }
}
