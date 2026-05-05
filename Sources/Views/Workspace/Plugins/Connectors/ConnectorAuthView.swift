import SwiftUI

struct ConnectorAuthView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared

    @State private var authType: ConnectorAuthConfig.AuthType
    @State private var apiKey = ""
    @State private var apiHeader = "X-API-Key"
    @State private var bearerToken = ""

    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var authURL = ""
    @State private var tokenURL = ""
    @State private var scopesString = ""

    init(connector: ConnectorDefinition) {
        self.connector = connector
        _authType = State(initialValue: connector.authConfig.type)
        _apiKey = State(initialValue: connector.authConfig.credentials["apiKey"] ?? "")
        _apiHeader = State(initialValue: connector.authConfig.credentials["headerName"] ?? "X-API-Key")
        _bearerToken = State(initialValue: connector.authConfig.credentials["token"] ?? "")

        if let oauth = connector.authConfig.oauthConfig {
            _clientID = State(initialValue: oauth.clientID)
            _clientSecret = State(initialValue: oauth.clientSecret)
            _authURL = State(initialValue: oauth.authURL)
            _tokenURL = State(initialValue: oauth.tokenURL)
            _scopesString = State(initialValue: oauth.scopes.joined(separator: ", "))
        }
    }

    var body: some View {
        Form {
            Section("Authentication Strategy") {
                Picker("Type", selection: $authType) {
                    Text("None").tag(ConnectorAuthConfig.AuthType.none)
                    Text("API Key").tag(ConnectorAuthConfig.AuthType.apiKey)
                    Text("Bearer Token").tag(ConnectorAuthConfig.AuthType.bearer)
                    Text("OAuth 2.0").tag(ConnectorAuthConfig.AuthType.oauth2)
                }
            }

            switch authType {
            case .none:
                Section {
                    Text("No authentication required for this connector.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            case .apiKey:
                Section("API Key Configuration") {
                    TextField("API Key", text: $apiKey)
                    TextField("Header Name", text: $apiHeader)
                }
            case .bearer:
                Section("Bearer Token") {
                    TextField("Token", text: $bearerToken)
                }
            case .oauth2:
                Section("OAuth 2.0 Config") {
                    TextField("Client ID", text: $clientID)
                    TextField("Client Secret", text: $clientSecret)
                    TextField("Authorization URL", text: $authURL)
                    TextField("Token URL", text: $tokenURL)
                    TextField("Scopes (comma separated)", text: $scopesString)
                }

                Section {
                    Button("Authorize & Test Connection") {
                        // Trigger OAuth2 flow simulation
                    }
                }
            }

            Section {
                Button("Save Auth Config") {
                    saveAuth()
                }
                .frame(maxWidth: .infinity)
                .bold()
            }
        }
        .navigationTitle("Authentication")
    }

    private func saveAuth() {
        var config = ConnectorAuthConfig(type: authType)

        switch authType {
        case .apiKey:
            config.credentials["apiKey"] = apiKey
            config.credentials["headerName"] = apiHeader
        case .bearer:
            config.credentials["token"] = bearerToken
        case .oauth2:
            let scopes = scopesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            config.oauthConfig = OAuthConfig(clientID: clientID, clientSecret: clientSecret, authURL: authURL, tokenURL: tokenURL, scopes: scopes)
        case .none:
            break
        }

        connector.authConfig = config
        manager.updateConnector(connector)

        // Securely store credentials via AuthManager
        if !apiKey.isEmpty { ConnectorAuthManager.shared.secureStore(key: "apiKey", value: apiKey, connectorID: connector.id) }
        if !bearerToken.isEmpty { ConnectorAuthManager.shared.secureStore(key: "token", value: bearerToken, connectorID: connector.id) }
    }
}
