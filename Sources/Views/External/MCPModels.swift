import Foundation
import SwiftUI

// MARK: - Auth Models

enum MCPAuthType: String, Codable, CaseIterable, Identifiable {
    case none, apiKey, bearerToken, basicAuth,
         oauth, oauth2AuthCode, oauth2ClientCredentials, customHeaders

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "No Authentication"
        case .apiKey: return "API Key"
        case .bearerToken: return "Bearer Token"
        case .basicAuth: return "Basic Auth"
        case .oauth, .oauth2AuthCode: return "OAuth2"
        case .oauth2ClientCredentials: return "OAuth2 (Client Credentials)"
        case .customHeaders: return "Custom Headers"
        }
    }

    var setupGuide: String {
        switch self {
        case .none:
            return "No credentials required for this server. Use for local or open-access MCP endpoints."
        case .apiKey:
            return "Provide the header name (e.g., X-API-Key) and the secret key. The key will be securely stored in your Keychain."
        case .bearerToken:
            return "Enter your personal access token. It will be sent in the 'Authorization: Bearer <token>' header."
        case .basicAuth:
            return "Enter your username and password. They will be base64-encoded and sent in the 'Authorization: Basic' header."
        case .oauth, .oauth2AuthCode:
            return "Standard OAuth2 PKCE flow. You will be redirected to the provider's login page to authorize this app."
        case .oauth2ClientCredentials:
            return "Service-to-service authentication. Requires a Client ID and Client Secret to obtain an access token."
        case .customHeaders:
            return "Define arbitrary key-value pairs that will be included in every request header."
        }
    }
}

struct MCPAuthConfig: Codable {
    var type: MCPAuthType = .none
    // API Key
    var apiKeyHeaderName: String = "X-API-Key"
    // Bearer / refresh
    var tokenEndpoint: String = ""
    // Basic Auth
    var username: String = ""
    // OAuth2 Auth Code
    var authorizationEndpoint: String = ""
    var redirectURI: String = "toolskit://oauth/callback"
    var clientId: String = ""
    var scopes: String = ""
    // OAuth2 Client Credentials
    var clientSecret: String = ""
    // Custom headers — stored as parallel arrays so it's Codable without a custom encoder
    var customHeaderKeys: [String] = []
    var customHeaderValues: [String] = []
    // Secrets NOT stored here; they live in Keychain only
}

// MARK: - Server & Tool Models

enum MCPConnectionStatus: String, Codable {
    case disconnected, connecting, authenticating, discovering, connected, failed

    var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .authenticating: return .blue
        case .discovering: return .purple
        case .connected: return .green
        case .failed: return .red
        }
    }

    var label: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .authenticating: return "Authenticating"
        case .discovering: return "Discovering Tools"
        case .connected: return "Connected"
        case .failed: return "Connection Failed"
        }
    }
}

struct MCPTool: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var inputSchema: MCPJSONSchema

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: MCPTool, rhs: MCPTool) -> Bool {
        lhs.name == rhs.name
    }
}

struct MCPJSONSchema: Codable {
    var type: String
    var properties: [String: MCPSchemaProperty]?
    var required: [String]?
}

struct MCPSchemaProperty: Codable {
    var type: String
    var description: String?
    var enumValues: [String]?
    private enum CodingKeys: String, CodingKey {
        case type, description, enumValues = "enum"
    }
}

struct MCPServer: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var baseURL: String
    var authConfig: MCPAuthConfig = MCPAuthConfig()
    var connectionStatus: MCPConnectionStatus = .disconnected
    var discoveredTools: [MCPTool] = []
    var serverInfo: MCPServerInfo?
    var lastConnected: Date?
    var lastError: String?
    var sessionId: String?
    var notes: String = ""
    var trafficLogs: [MCPTrafficLog]? = []
}

struct MCPTrafficLog: Identifiable, Codable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var direction: MCPTrafficDirection
    var method: String?
    var payload: String
}

enum MCPTrafficDirection: String, Codable {
    case request, response
}

struct MCPServerInfo: Codable {
    var name: String
    var version: String
    var protocolVersion: String
}

// MARK: - JSON-RPC 2.0 Wire Types

struct MCPRequest: Encodable {
    let jsonrpc: String = "2.0"
    let id: Int?
    let method: String
    let params: MCPRequestParams?
}

enum MCPRequestParams: Encodable {
    case initialize(MCPInitializeParams)
    case empty
    case toolCall(MCPToolCallParams)
    case notification
    case custom(AnyCodable)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .initialize(let params):
            try container.encode(params)
        case .empty:
            try container.encode([String: String]())
        case .toolCall(let params):
            try container.encode(params)
        case .notification:
            // Notifications often have no params or are encoded differently
            try container.encode([String: String]())
        case .custom(let anyCodable):
            try container.encode(anyCodable)
        }
    }
}

struct MCPInitializeParams: Encodable {
    let protocolVersion: String
    let capabilities: MCPClientCapabilities = MCPClientCapabilities()
    let clientInfo: MCPClientInfo = MCPClientInfo()

    init(protocolVersion: String = "2025-06-18") {
        self.protocolVersion = protocolVersion
    }
}

struct MCPClientCapabilities: Encodable {
    let sampling: [String: String] = [:]
}

struct MCPClientInfo: Encodable {
    let name: String = "Tools-Kit"
    let version: String = "1.0"
}

struct MCPToolCallParams: Encodable {
    let name: String
    let arguments: [String: AnyCodable]
}

struct MCPResponse: Decodable {
    let jsonrpc: String
    let id: Int?
    let result: MCPResult?
    let error: MCPResponseError?
}

struct MCPResult: Decodable {
    let protocolVersion: String?
    let capabilities: MCPServerCapabilities?
    let serverInfo: MCPServerInfo?
    let tools: [MCPTool]?
    let content: [MCPContentBlock]?
    var additionalFields: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case protocolVersion, capabilities, serverInfo, tools, content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        protocolVersion = try container.decodeIfPresent(String.self, forKey: .protocolVersion)
        capabilities = try container.decodeIfPresent(MCPServerCapabilities.self, forKey: .capabilities)
        serverInfo = try container.decodeIfPresent(MCPServerInfo.self, forKey: .serverInfo)
        tools = try container.decodeIfPresent([MCPTool].self, forKey: .tools)
        content = try container.decodeIfPresent([MCPContentBlock].self, forKey: .content)

        // Decode additional fields
        let allKeysContainer = try decoder.container(keyedBy: AnyCodingKey.self)
        let allKeys = allKeysContainer.allKeys
        var extra = [String: AnyCodable]()
        for key in allKeys {
            if CodingKeys(stringValue: key.stringValue) == nil {
                if let value = try? allKeysContainer.decode(AnyCodable.self, forKey: key) {
                    extra[key.stringValue] = value
                }
            }
        }
        self.additionalFields = extra.isEmpty ? nil : extra
    }
}

struct MCPServerCapabilities: Decodable {
    let tools: MCPToolCapability?
    let resources: [String: Bool]?
    let prompts: [String: Bool]?
    var additionalFields: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case tools, resources, prompts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tools = try container.decodeIfPresent(MCPToolCapability.self, forKey: .tools)
        resources = try container.decodeIfPresent([String: Bool].self, forKey: .resources)
        prompts = try container.decodeIfPresent([String: Bool].self, forKey: .prompts)

        // Decode additional fields
        let allKeysContainer = try decoder.container(keyedBy: AnyCodingKey.self)
        let allKeys = allKeysContainer.allKeys
        var extra = [String: AnyCodable]()
        for key in allKeys {
            if CodingKeys(stringValue: key.stringValue) == nil {
                if let value = try? allKeysContainer.decode(AnyCodable.self, forKey: key) {
                    extra[key.stringValue] = value
                }
            }
        }
        self.additionalFields = extra.isEmpty ? nil : extra
    }
}

struct MCPToolCapability: Decodable {
    let listChanged: Bool?
}

struct MCPContentBlock: Decodable {
    let type: String
    let text: String?
}

struct MCPResponseError: Decodable {
    let code: Int
    let message: String
}

// MARK: - Codable Helpers

struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}


// MARK: - Persona ↔ MCP Bridge Models

struct MCPToolInvocation: Identifiable {
    var id: UUID = UUID()
    var serverId: UUID
    var serverName: String
    var toolName: String
    var purpose: String
    var arguments: [String: Any]
    var status: MCPInvocationStatus
    var result: String?
    var startedAt: Date = Date()
    var completedAt: Date?
    var errorMessage: String?
}

enum MCPInvocationStatus {
    case pending, connecting, executing, completed, failed

    var label: String {
        switch self {
        case .pending: return "Pending"
        case .connecting: return "Connecting"
        case .executing: return "Executing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .gray
        case .connecting: return .orange
        case .executing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .connecting: return "arrow.2.circlepath"
        case .executing: return "terminal"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Errors

enum MCPError: LocalizedError {
    case invalidURL
    case authenticationFailed(String)
    case connectionFailed(String)
    case serverError(code: Int, message: String)
    case toolNotFound(String)
    case invalidResponse
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The server URL is invalid."
        case .authenticationFailed(let reason): return "Authentication failed: \(reason)"
        case .connectionFailed(let reason): return "Connection failed: \(reason)"
        case .serverError(let code, let message): return "Server error (\(code)): \(message)"
        case .toolNotFound(let name): return "Tool '\(name)' not found."
        case .invalidResponse: return "The server returned an invalid response."
        case .keychainError(let status): return "Keychain error: \(status)"
        }
    }
}
