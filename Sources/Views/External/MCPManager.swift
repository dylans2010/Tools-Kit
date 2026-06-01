import Foundation
import Combine
import SwiftUI
import AuthenticationServices
import Security

@MainActor
public final class MCPManager: ObservableObject {
    public static let shared = MCPManager()

    @Published public var servers: [MCPServer] = []
    @Published public var activeInvocations: [MCPToolInvocation] = []
    @Published public var isLoading: Bool = false
    @Published public var toolRegistry: [String: [MCPTool]] = [:] // serverID: [tools]

    private let storageKey = "mcp_servers_v2"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadServers()
        // Migrate from old storage if exists
        if servers.isEmpty {
            migrateFromV1()
        }
    }

    // MARK: - Persistence

    private func saveServers() {
        // Limit traffic logs
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
            // Rebuild tool registry from persisted tools
            for server in servers {
                toolRegistry[server.id.uuidString] = server.discoveredTools
            }
        }
    }

    private func migrateFromV1() {
        let oldKey = "mcp_servers"
        if let data = UserDefaults.standard.data(forKey: oldKey),
           let decoded = try? JSONDecoder().decode([MCPServer].self, from: data) {
            self.servers = decoded
            saveServers()
            UserDefaults.standard.removeObject(forKey: oldKey)
        }
    }

    // MARK: - Keychain Helpers

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

    private func loadFromKeychain(key: String) -> String? {
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

    public func saveSecret(_ value: String, key: String, for server: MCPServer) {
        saveToKeychain(key: "mcp_\(server.id)_\(key)", value: value)
    }

    public func loadSecret(key: String, for server: MCPServer) -> String {
        return loadFromKeychain(key: "mcp_\(server.id)_\(key)") ?? ""
    }

    // MARK: - Public API

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
        saveServers()
    }

    public func connect(to server: MCPServer) async throws {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }

        servers[index].connectionStatus = .connecting
        servers[index].lastError = nil
        saveServers()

        do {
            // 1. Initialize Handshake (v2025-06-18)
            let protocolVersions = ["2025-06-18", "2024-11-05"]
            var lastErr: Error? = nil
            var initResult: AnyCodable? = nil

            for version in protocolVersions {
                do {
                    let initParams = MCPInitializeParams(protocolVersion: version)
                    let initRequest = MCPRequest(id: 1, method: "initialize", params: AnyCodable(initParams))
                    let response = try await send(request: initRequest, to: servers[index], decoding: MCPResponse.self)

                    if let error = response.error {
                        throw MCPError.serverError(code: error.code, message: error.message, data: error.data)
                    }
                    initResult = response.result
                    break
                } catch {
                    lastErr = error
                    continue
                }
            }

            guard let result = initResult else {
                throw lastErr ?? MCPError.invalidResponse("Handshake failed for all supported protocol versions.")
            }

            // Extract server info and capabilities
            let resultDict = result.value as? [String: Any]
            if let serverInfoDict = resultDict?["serverInfo"] as? [String: Any],
               let name = serverInfoDict["name"] as? String,
               let version = serverInfoDict["version"] as? String {
                servers[index].serverInfo = MCPServerInfo(name: name, version: version, protocolVersion: (resultDict?["protocolVersion"] as? String) ?? "unknown")
            }

            // 2. Initialized Notification
            let initializedNotification = MCPRequest(id: nil, method: "notifications/initialized", params: nil)
            _ = try? await send(request: initializedNotification, to: servers[index], decoding: MCPResponse.self)

            // 3. List Tools
            servers[index].connectionStatus = .discovering
            saveServers()

            let tools = try await discoverTools(for: servers[index])
            servers[index].discoveredTools = tools
            toolRegistry[servers[index].id.uuidString] = tools
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

    public func disconnect(server: MCPServer) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index].connectionStatus = .disconnected
            saveServers()
        }
    }

    public func discoverTools(for server: MCPServer) async throws -> [MCPTool] {
        let request = MCPRequest(id: 2, method: "tools/list", params: nil)
        let response = try await send(request: request, to: server, decoding: MCPResponse.self)

        if let error = response.error {
            throw MCPError.serverError(code: error.code, message: error.message, data: error.data)
        }

        guard let resultValue = response.result?.value as? [String: Any],
              let toolsArray = resultValue["tools"] as? [[String: Any]] else {
            return []
        }

        let toolsData = try JSONSerialization.data(withJSONObject: toolsArray)
        return try JSONDecoder().decode([MCPTool].self, from: toolsData)
    }

    public func callTool(
        named toolName: String,
        on server: MCPServer,
        arguments: [String: Any],
        purpose: String
    ) async throws -> String {
        let invocationId = UUID()
        let anyArgs = arguments.mapValues { AnyCodable($0) }
        let invocation = MCPToolInvocation(
            serverId: server.id,
            serverName: server.name,
            toolName: toolName,
            purpose: purpose,
            arguments: anyArgs,
            status: .connecting
        )
        invocation.id = invocationId

        activeInvocations.insert(invocation, at: 0)

        do {
            if server.connectionStatus != .connected {
                try await connect(to: server)
            }

            updateInvocation(id: invocationId, status: .executing)

            let toolCallParams = MCPToolCallParams(name: toolName, arguments: anyArgs)
            let request = MCPRequest(id: 3, method: "tools/call", params: AnyCodable(toolCallParams))

            let response = try await send(request: request, to: server, decoding: MCPResponse.self)

            if let error = response.error {
                throw MCPError.serverError(code: error.code, message: error.message, data: error.data)
            }

            guard let resultDict = response.result?.value as? [String: Any],
                  let content = resultDict["content"] as? [[String: Any]] else {
                throw MCPError.invalidResponse("Server returned empty or invalid result for tool call.")
            }

            let resultText = content.compactMap { block -> String? in
                if let type = block["type"] as? String, type == "text" {
                    return block["text"] as? String
                }
                return nil
            }.joined(separator: "\n")

            updateInvocation(id: invocationId, status: .completed, result: resultText)
            return resultText

        } catch {
            updateInvocation(id: invocationId, status: .failed, errorMessage: error.localizedDescription)
            throw error
        }
    }

    public func testConnection(server: MCPServer) async throws -> MCPServerInfo {
        let initParams = MCPInitializeParams()
        let initRequest = MCPRequest(id: 1, method: "initialize", params: AnyCodable(initParams))
        let response = try await send(request: initRequest, to: server, decoding: MCPResponse.self)

        if let error = response.error {
            throw MCPError.serverError(code: error.code, message: error.message, data: error.data)
        }

        guard let resultDict = response.result?.value as? [String: Any],
              let serverInfoDict = resultDict["serverInfo"] as? [String: Any],
              let name = serverInfoDict["name"] as? String,
              let version = serverInfoDict["version"] as? String else {
            throw MCPError.invalidResponse("Server info missing in handshake result.")
        }

        return MCPServerInfo(name: name, version: version, protocolVersion: (resultDict["protocolVersion"] as? String) ?? "unknown")
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

    private func send<R: Decodable>(
        request: MCPRequest,
        to server: MCPServer,
        decoding: R.Type
    ) async throws -> R {
        let headers = try await authHeaders(for: server)
        let startTime = Date()

        do {
            let response: R = try await MCPService.shared.send(request: request, to: server, authHeaders: headers)
            let latency = Date().timeIntervalSince(startTime) * 1000

            if let index = servers.firstIndex(where: { $0.id == server.id }) {
                servers[index].latency = latency
            }

            logTraffic(direction: .request, method: request.method, payload: String(describing: request), for: server)
            logTraffic(direction: .response, method: request.method, payload: String(describing: response), for: server)

            return response
        } catch {
            logTraffic(direction: .response, method: request.method, payload: "Error: \(error.localizedDescription)", for: server)
            throw error
        }
    }

    private func logTraffic(direction: MCPTrafficDirection, method: String?, payload: String, for server: MCPServer) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            let log = MCPTrafficLog(direction: direction, method: method, payload: payload)
            if servers[index].trafficLogs == nil { servers[index].trafficLogs = [] }
            servers[index].trafficLogs?.append(log)
        }
    }

    public func getAllTools() -> [String: [MCPTool]] {
        return toolRegistry
    }

    public func getConnectedTools() -> [String: [MCPTool]] {
        let connectedServerIDs = servers.filter { $0.connectionStatus == .connected }.map { $0.id.uuidString }
        return toolRegistry.filter { connectedServerIDs.contains($0.key) }
    }
}
