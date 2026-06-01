import Foundation
import Combine
import SwiftUI
import AuthenticationServices
import Security

@MainActor
final class MCPManager: ObservableObject {
    static let shared = MCPManager()

    @Published var servers: [MCPServer] = []
    @Published var activeInvocations: [MCPToolInvocation] = []
    @Published var isLoading: Bool = false

    private let storageKey = "mcp_servers"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadServers()
    }

    // MARK: - Persistence

    private func saveServers() {
        if let encoded = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadServers() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([MCPServer].self, from: data) {
            self.servers = decoded
        }
    }

    // MARK: - Keychain Helpers

    func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }

    func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }

    func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    func saveSecret(_ value: String, key: String, for server: MCPServer) {
        saveToKeychain(key: "mcp_\(server.id)_\(key)", value: value)
    }

    func loadSecret(key: String, for server: MCPServer) -> String {
        return loadFromKeychain(key: "mcp_\(server.id)_\(key)") ?? ""
    }

    // MARK: - Public API

    func addServer(_ server: MCPServer) {
        servers.append(server)
        saveServers()
    }

    func updateServer(_ server: MCPServer) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveServers()
        }
    }

    func removeServer(id: UUID) {
        if let server = servers.first(where: { $0.id == id }) {
            // Clean up keychain
            deleteFromKeychain(key: "mcp_\(id)_apiKey")
            deleteFromKeychain(key: "mcp_\(id)_bearerToken")
            deleteFromKeychain(key: "mcp_\(id)_password")
            deleteFromKeychain(key: "mcp_\(id)_accessToken")
            deleteFromKeychain(key: "mcp_\(id)_refreshToken")
            deleteFromKeychain(key: "mcp_\(id)_clientSecret")

            servers.removeAll { $0.id == id }
            saveServers()
        }
    }

    func connect(to server: MCPServer) async throws {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }

        servers[index].connectionStatus = .connecting
        servers[index].lastError = nil
        saveServers()

        do {
            // 1. Initialize Handshake
            let initParams = MCPInitializeParams()
            let initRequest = MCPRequest(id: 1, method: "initialize", params: .initialize(initParams))
            let initResponse = try await send(request: initRequest, to: servers[index], decoding: MCPResponse.self)

            if let error = initResponse.error {
                throw MCPError.serverError(code: error.code, message: error.message)
            }

            guard let result = initResponse.result else {
                throw MCPError.invalidResponse
            }

            // Update server info and capabilities from handshake
            servers[index].serverInfo = result.serverInfo
            servers[index].connectionStatus = .authenticating

            // 2. Initialized Notification (Protocol requirement)
            let initializedNotification = MCPRequest(id: nil, method: "notifications/initialized", params: .notification)
            _ = try? await send(request: initializedNotification, to: servers[index], decoding: MCPResponse.self)

            // 3. Discover Tools Dynamically
            servers[index].connectionStatus = .discovering
            saveServers()

            let tools = try await discoverTools(for: servers[index])

            // Filter out any potential non-functional tools and update
            servers[index].discoveredTools = tools.filter { !$0.name.isEmpty }
            servers[index].connectionStatus = .connected
            servers[index].lastConnected = Date()
            saveServers()

        } catch {
            servers[index].connectionStatus = .failed
            servers[index].lastError = error.localizedDescription
            saveServers()
            throw error
        }
    }

    func disconnect(server: MCPServer) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index].connectionStatus = .disconnected
            servers[index].sessionId = nil
            saveServers()
        }
    }

    func discoverTools(for server: MCPServer) async throws -> [MCPTool] {
        let request = MCPRequest(id: 2, method: "tools/list", params: .empty)
        let response = try await send(request: request, to: server, decoding: MCPResponse.self)

        if let error = response.error {
            throw MCPError.serverError(code: error.code, message: error.message)
        }

        return response.result?.tools ?? []
    }

    func callTool(
        named toolName: String,
        on server: MCPServer,
        arguments: [String: Any],
        purpose: String
    ) async throws -> String {
        let invocationId = UUID()
        let invocation = MCPToolInvocation(
            id: invocationId,
            serverId: server.id,
            serverName: server.name,
            toolName: toolName,
            purpose: purpose,
            arguments: arguments,
            status: .connecting
        )

        activeInvocations.insert(invocation, at: 0)

        do {
            // Ensure connected
            if server.connectionStatus != .connected {
                try await connect(to: server)
            }

            updateInvocation(id: invocationId, status: .executing)

            let anyArgs = arguments.mapValues { AnyCodable($0) }
            let toolCallParams = MCPToolCallParams(name: toolName, arguments: anyArgs)
            let request = MCPRequest(id: 3, method: "tools/call", params: .toolCall(toolCallParams))

            let response = try await send(request: request, to: server, decoding: MCPResponse.self)

            if let error = response.error {
                throw MCPError.serverError(code: error.code, message: error.message)
            }

            let resultText = response.result?.content?.compactMap { $0.text }.joined(separator: "\n") ?? "No output"
            updateInvocation(id: invocationId, status: .completed, result: resultText)
            return resultText

        } catch {
            updateInvocation(id: invocationId, status: .failed, errorMessage: error.localizedDescription)
            throw error
        }
    }

    func testConnection(server: MCPServer) async throws -> MCPServerInfo {
        // 1. Validate URL reachability
        guard let url = URL(string: server.baseURL) else {
            throw MCPError.invalidURL
        }

        // 2. Perform initialization handshake to verify protocol support
        let initParams = MCPInitializeParams()
        let initRequest = MCPRequest(id: 1, method: "initialize", params: .initialize(initParams))

        let response = try await send(request: initRequest, to: server, decoding: MCPResponse.self)

        if let error = response.error {
            // Check specifically for auth errors
            if error.code == 401 || error.code == 403 {
                throw MCPError.authenticationFailed(error.message)
            }
            throw MCPError.serverError(code: error.code, message: error.message)
        }

        guard let info = response.result?.serverInfo else {
            throw MCPError.invalidResponse
        }

        // 3. Optional: Verify tools list capability
        if let capabilities = response.result?.capabilities, capabilities.tools == nil {
            print("Warning: Server does not declare tool capabilities")
        }

        return info
    }

    // MARK: - Private Core

    private func updateInvocation(id: UUID, status: MCPInvocationStatus, result: String? = nil, errorMessage: String? = nil) {
        if let index = activeInvocations.firstIndex(where: { $0.id == id }) {
            activeInvocations[index].status = status
            if let result = result { activeInvocations[index].result = result }
            if let errorMessage = errorMessage { activeInvocations[index].errorMessage = errorMessage }
            if status == .completed || status == .failed {
                activeInvocations[index].completedAt = Date()
            }
        }
    }

    private func authHeaders(for server: MCPServer) async throws -> [String: String] {
        var headers: [String: String] = [:]

        switch server.authConfig.type {
        case .none:
            break
        case .apiKey:
            let key = loadSecret(key: "apiKey", for: server)
            headers[server.authConfig.apiKeyHeaderName] = key
        case .bearerToken:
            let token = loadSecret(key: "bearerToken", for: server)
            headers["Authorization"] = "Bearer \(token)"
        case .basicAuth:
            let password = loadSecret(key: "password", for: server)
            let authString = "\(server.authConfig.username):\(password)"
            if let data = authString.data(using: .utf8) {
                headers["Authorization"] = "Basic \(data.base64EncodedString())"
            }
        case .oauth2AuthCode:
            var token = loadSecret(key: "accessToken", for: server)
            // In a real app, check expiry and refresh if needed
            headers["Authorization"] = "Bearer \(token)"
        case .oauth2ClientCredentials:
            var token = loadSecret(key: "accessToken", for: server)
            if token.isEmpty {
                token = try await refreshClientCredentials(server: server)
            }
            headers["Authorization"] = "Bearer \(token)"
        case .customHeaders:
            for (key, value) in zip(server.authConfig.customHeaderKeys, server.authConfig.customHeaderValues) {
                headers[key] = value
            }
        }

        return headers
    }

    private func refreshClientCredentials(server: MCPServer) async throws -> String {
        guard let url = URL(string: server.authConfig.tokenEndpoint) else { throw MCPError.invalidURL }
        let clientSecret = loadSecret(key: "clientSecret", for: server)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=client_credentials&client_id=\(server.authConfig.clientId)&client_secret=\(clientSecret)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw MCPError.authenticationFailed("Token request failed")
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        saveSecret(tokenResponse.access_token, key: "accessToken", for: server)
        return tokenResponse.access_token
    }

    private func send<R: Decodable>(
        request: MCPRequest,
        to server: MCPServer,
        decoding: R.Type
    ) async throws -> R {
        let headers = try await authHeaders(for: server)
        return try await MCPService.shared.send(request: request, to: server, authHeaders: headers)
    }

    // MARK: - OAuth2 PKCE

    internal func performOAuth2PKCE(server: MCPServer) async throws {
        // ASWebAuthenticationSession logic to be integrated with AppCoordinator
        print("OAuth2 PKCE initiated for \(server.name)")
    }
}

struct OAuthTokenResponse: Decodable {
    let access_token: String
    let token_type: String?
    let expires_in: Int?
    let refresh_token: String?
}
