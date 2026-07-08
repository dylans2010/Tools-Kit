import Foundation
import Combine
import SwiftUI
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
import Security
import SwiftMCP

@MainActor
public final class MCPManager: ObservableObject {
    public static let shared = MCPManager()

    @Published public var servers: [MCPServer] = []
    @Published public var activeInvocations: [MCPToolInvocation] = []
    @Published public var isLoading: Bool = false
    @Published public var toolRegistry: [String: [MCPTool]] = [:] // serverID: [tools]

    private var proxies: [UUID: MCPServerProxy] = [:]
    private let storageKey = "mcp_servers_v3"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadServers()
    }

    // MARK: - Persistence

    private func saveServers() {
        for i in 0..<servers.count {
            if let logs = servers[i].trafficLogs, logs.count > 50 {
                servers[i].trafficLogs = Array(logs.suffix(50))
            }
        }
        if let encoded = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadServers() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([MCPServer].self, from: data) {
            self.servers = decoded
            for server in servers {
                toolRegistry[server.id.uuidString] = server.discoveredTools
                // Populate central registry on load
                MCPToolRegistry.shared.updateTools(for: server.id, tools: server.discoveredTools)
            }
        }
    }

    // MARK: - Core Connection Logic

    public func connect(to server: MCPServer) async throws {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }

        updateStatus(id: server.id, to: .connecting)

        do {
            // 1. Validation
            updateStatus(id: server.id, to: .validating)
            try await validateEndpoint(server: servers[index])

            // 2. Transport Configuration
            let headers = try await getAuthHeaders(for: servers[index])
            let proxy: MCPServerProxy
            switch servers[index].transportType {
            case .httpSse:
                guard let url = URL(string: servers[index].baseURL) else { throw MCPError.invalidURL }
                let sseConfig = MCPServerSseConfig(url: url, headers: headers)
                proxy = MCPServerProxy(config: .sse(config: sseConfig))
            case .tcp:
                let tcpConfig = MCPServerTcpConfig(serviceName: servers[index].name)
                proxy = MCPServerProxy(config: .tcp(config: tcpConfig))
            case .stdio:
                throw MCPError.connectionFailed("stdio transport not supported on iOS.")
            }

            // 3. Initialize
            updateStatus(id: server.id, to: .initializing)
            try await proxy.connect()
            proxies[server.id] = proxy

            // 4. Discover Tools
            updateStatus(id: server.id, to: .discoveringTools)
            let tools = try await discoverToolsViaProxy(proxy)

            // 5. Finalize
            if let idx = servers.firstIndex(where: { $0.id == server.id }) {
                servers[idx].discoveredTools = tools
                servers[idx].connectionStatus = .connected
                servers[idx].lastConnected = Date()
                servers[idx].lastError = nil
                toolRegistry[server.id.uuidString] = tools

                // Update Central Registry
                MCPToolRegistry.shared.updateTools(for: server.id, tools: tools)

                // Capture server info if available
                // Note: SwiftMCP doesn't expose serverInfo directly on proxy yet in a simple way
                // we'd need to intercept the initialize response or wait for property exposure.
            }
            saveServers()

        } catch {
            updateStatus(id: server.id, to: .failed, error: error.localizedDescription)
            throw error
        }
    }

    private func updateStatus(id: UUID, to status: MCPConnectionStatus, error: String? = nil) {
        if let index = servers.firstIndex(where: { $0.id == id }) {
            servers[index].connectionStatus = status
            if let error = error {
                servers[index].lastError = error
            }
            saveServers()
        }
    }

    private func validateEndpoint(server: MCPServer) async throws {
        guard let url = URL(string: server.baseURL) else { throw MCPError.invalidURL }

        // 1. Protocol Enforcement
        if !server.baseURL.lowercased().hasPrefix("https://") && !server.isTrusted {
            throw MCPError.connectionFailed("Insecure connection blocked. MCP requires HTTPS for production endpoints unless explicitly trusted.")
        }

        // 2. Reachability & Protocol Probe
        // We try to see if the endpoint responds to a simple probe or if it's a known non-MCP API
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw MCPError.connectionFailed("The server did not return a valid HTTP response.")
            }

            // If it's a standard web page (HTML), it's likely not an MCP server
            if let contentType = http.allHeaderFields["Content-Type"] as? String,
               contentType.contains("text/html") {
                throw MCPError.connectionFailed("This endpoint appears to be a web page, not an MCP server.")
            }

            // Check for common non-MCP API patterns if necessary
            // For now, if it returns 404 on GET but we expect SSE, that might be normal for some implementations
            // until we POST to the /mcp endpoint.

            if http.statusCode == 401 || http.statusCode == 403 {
                // This is fine, it means it's an API that needs auth, which we'll provide during initialization
            }

        } catch let error as NSError {
            if error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorTimedOut:
                    throw MCPError.timeout
                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    throw MCPError.connectionFailed("Host unreachable. Please check the URL and your connection.")
                default:
                    throw MCPError.connectionFailed("Network error: \(error.localizedDescription)")
                }
            }
            throw MCPError.connectionFailed("Validation failed: \(error.localizedDescription)")
        }
    }

    private func getAuthHeaders(for server: MCPServer) async throws -> [String: String] {
        var headers: [String: String] = [:]
        switch server.authConfig.type {
        case .none: break
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
        case .customHeaders:
            for (key, value) in zip(server.authConfig.customHeaderKeys, server.authConfig.customHeaderValues) {
                headers[key] = value
            }
        default: break
        }
        return headers
    }

    private func getToKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func discoverToolsViaProxy(_ proxy: MCPServerProxy) async throws -> [MCPTool] {
        let swiftTools = try await proxy.listTools()

        return swiftTools.map { tool in
            MCPTool(
                name: tool.name,
                description: tool.description ?? "",
                inputSchema: AnyCodable(tool.inputSchema)
            )
        }
    }

    public func disconnect(server: MCPServer) {
        proxies.removeValue(forKey: server.id)
        updateStatus(id: server.id, to: .disconnected)
    }

    // MARK: - Tool Execution

    public func callTool(
        named toolName: String,
        on server: MCPServer,
        arguments: [String: Any],
        purpose: String
    ) async throws -> String {
        guard let proxy = proxies[server.id] else {
            try await connect(to: server)
            return try await callTool(named: toolName, on: server, arguments: arguments, purpose: purpose)
        }

        let invocationId = UUID()
        let anyArgs = arguments.mapValues { AnyCodable($0) }
        var invocation = MCPToolInvocation(
            serverId: server.id,
            serverName: server.name,
            toolName: toolName,
            purpose: purpose,
            arguments: anyArgs,
            status: .executing
        )
        invocation.id = invocationId
        activeInvocations.insert(invocation, at: 0)

        do {
            let jsonArgs = try makeJSONDictionary(from: arguments)
            let outputText = try await proxy.callTool(toolName, arguments: jsonArgs)

            updateInvocation(id: invocationId, status: .completed, result: outputText)
            return outputText
        } catch {
            updateInvocation(id: invocationId, status: .failed, errorMessage: error.localizedDescription)
            throw error
        }
    }

    private func makeJSONDictionary(from arguments: [String: Any]) throws -> JSONDictionary {
        let encodableArguments = arguments.mapValues { AnyCodable($0) }
        let data = try JSONEncoder().encode(encodableArguments)
        return try JSONDecoder().decode(JSONDictionary.self, from: data)
    }

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

    // MARK: - Server Management

    public func addServer(_ server: MCPServer) {
        if !servers.contains(where: { $0.id == server.id }) {
            servers.append(server)
            saveServers()
        }
    }

    public func updateServer(_ server: MCPServer) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            toolRegistry[server.id.uuidString] = server.discoveredTools
            saveServers()
        }
    }

    public func removeServer(id: UUID) {
        servers.removeAll { $0.id == id }
        toolRegistry.removeValue(forKey: id.uuidString)
        proxies.removeValue(forKey: id)
        saveServers()
    }

    public func saveSecret(_ value: String, key: String, for server: MCPServer) {
        saveToKeychain(key: "mcp_\(server.id)_\(key)", value: value)
    }

    public func loadSecret(key: String, for server: MCPServer) -> String {
        return getToKeychain(key: "mcp_\(server.id)_\(key)") ?? ""
    }

    public func testConnection(server: MCPServer) async throws -> MCPServerInfo {
        guard let url = URL(string: server.baseURL) else { throw MCPError.invalidURL }
        let headers = try await getAuthHeaders(for: server)
        let sseConfig = MCPServerSseConfig(url: url, headers: headers)
        let proxy = MCPServerProxy(config: .sse(config: sseConfig))

        try await proxy.connect()

        // MCPServerProxy might not have public access to serverInfo yet, we rely on successful connect
        return MCPServerInfo(name: server.name, version: "unknown", protocolVersion: "unknown")
    }

    public func getAllTools() -> [String: [MCPTool]] {
        return toolRegistry
    }

    public func getConnectedTools() -> [String: [MCPTool]] {
        let connectedServerIDs = servers.filter { $0.connectionStatus == .connected }.map { $0.id.uuidString }
        return toolRegistry.filter { connectedServerIDs.contains($0.key) }
    }
}
