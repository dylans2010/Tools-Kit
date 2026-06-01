import Foundation
import SwiftUI
import SwiftMCP

// MARK: - Auth Models

public enum MCPAuthType: String, Codable, CaseIterable, Identifiable {
    case none, apiKey, bearerToken, basicAuth,
         oauth, oauth2AuthCode, oauth2ClientCredentials, customHeaders

    public var id: String { rawValue }

    public var displayName: String {
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

    public var setupGuide: String {
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

public struct MCPAuthConfig: Codable {
    public var type: MCPAuthType = .none
    public var apiKeyHeaderName: String = "X-API-Key"
    public var tokenEndpoint: String = ""
    public var username: String = ""
    public var authorizationEndpoint: String = ""
    public var redirectURI: String = "toolskit://oauth/callback"
    public var clientId: String = ""
    public var scopes: String = ""
    public var clientSecret: String = ""
    public var customHeaderKeys: [String] = []
    public var customHeaderValues: [String] = []

    public init() {}
}

// MARK: - Server & Tool Models

public enum MCPConnectionStatus: String, Codable {
    case disconnected, connecting, validating, initializing, discoveringTools, connected, degraded, reconnecting, failed

    public var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .validating: return .blue
        case .initializing: return .cyan
        case .discoveringTools: return .purple
        case .connected: return .green
        case .degraded: return .yellow
        case .reconnecting: return .orange
        case .failed: return .red
        }
    }

    public var label: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .validating: return "Validating"
        case .initializing: return "Initializing"
        case .discoveringTools: return "Discovering Tools"
        case .connected: return "Connected"
        case .degraded: return "Degraded"
        case .reconnecting: return "Reconnecting"
        case .failed: return "Connection Failed"
        }
    }
}

public struct MCPTool: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var name: String
    public var description: String
    public var inputSchema: AnyCodable

    public init(name: String, description: String, inputSchema: AnyCodable) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    public static func == (lhs: MCPTool, rhs: MCPTool) -> Bool {
        lhs.name == rhs.name
    }
}

public struct MCPServer: Identifiable, Codable {
    public var id: UUID = UUID()
    public var name: String
    public var baseURL: String
    public var transportType: MCPTransportType = .httpSse
    public var authConfig: MCPAuthConfig = MCPAuthConfig()
    public var connectionStatus: MCPConnectionStatus = .disconnected
    public var discoveredTools: [MCPTool] = []
    public var serverInfo: MCPServerInfo?
    public var lastConnected: Date?
    public var lastError: String?
    public var sessionId: String?
    public var notes: String = ""
    public var trafficLogs: [MCPTrafficLog]? = []
    public var latency: Double? // in milliseconds
    public var isTrusted: Bool = false
    public var capabilities: AnyCodable?

    public init(name: String, baseURL: String, authConfig: MCPAuthConfig = MCPAuthConfig()) {
        self.name = name
        self.baseURL = baseURL
        self.authConfig = authConfig
    }
}

public enum MCPTransportType: String, Codable, CaseIterable, Identifiable {
    case httpSse, stdio, tcp
    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .httpSse: return "HTTP + SSE"
        case .stdio: return "Standard I/O"
        case .tcp: return "TCP + Bonjour"
        }
    }
}

public struct MCPTrafficLog: Identifiable, Codable {
    public var id: UUID = UUID()
    public var timestamp: Date = Date()
    public var direction: MCPTrafficDirection
    public var method: String?
    public var payload: String

    public init(direction: MCPTrafficDirection, method: String?, payload: String) {
        self.direction = direction
        self.method = method
        self.payload = payload
    }
}

public enum MCPTrafficDirection: String, Codable {
    case request, response
}

public struct MCPServerInfo: Codable {
    public var name: String
    public var version: String
    public var protocolVersion: String
}

// MARK: - JSON-RPC 2.0 Wire Types (Deprecated in favor of SwiftMCP where possible)

public struct MCPRequest: Encodable {
    public let jsonrpc: String = "2.0"
    public let id: Int?
    public let method: String
    public let params: AnyCodable?

    public init(id: Int?, method: String, params: AnyCodable?) {
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct MCPInitializeParams: Encodable {
    public let protocolVersion: String
    public let capabilities: MCPClientCapabilities = MCPClientCapabilities()
    public let clientInfo: MCPClientInfo = MCPClientInfo()

    public init(protocolVersion: String = "2025-06-18") {
        self.protocolVersion = protocolVersion
    }
}

public struct MCPClientCapabilities: Encodable {
    public let sampling: [String: String]? = [:]
    public let roots: MCPRootsCapability? = MCPRootsCapability(listChanged: true)
}

public struct MCPRootsCapability: Encodable {
    public let listChanged: Bool
}

public struct MCPClientInfo: Codable {
    public let name: String = "Tools-Kit"
    public let version: String = "1.0"
}

public struct MCPToolCallParams: Encodable {
    public let name: String
    public let arguments: [String: AnyCodable]

    public init(name: String, arguments: [String: AnyCodable]) {
        self.name = name
        self.arguments = arguments
    }
}

public struct MCPResponse: Decodable {
    public let jsonrpc: String
    public let id: Int?
    public let result: AnyCodable?
    public let error: MCPResponseError?
}

public struct MCPResponseError: Codable {
    public let code: Int
    public let message: String
    public let data: AnyCodable?
}

// MARK: - Persona ↔ MCP Bridge Models

public struct MCPToolInvocation: Identifiable, Codable {
    public var id: UUID = UUID()
    public var serverId: UUID
    public var serverName: String
    public var toolName: String
    public var purpose: String
    public var arguments: [String: AnyCodable]
    public var status: MCPInvocationStatus
    public var result: String?
    public var startedAt: Date = Date()
    public var completedAt: Date?
    public var errorMessage: String?

    public init(serverId: UUID, serverName: String, toolName: String, purpose: String, arguments: [String: AnyCodable], status: MCPInvocationStatus) {
        self.serverId = serverId
        self.serverName = serverName
        self.toolName = toolName
        self.purpose = purpose
        self.arguments = arguments
        self.status = status
    }
}

public enum MCPInvocationStatus: String, Codable {
    case pending, connecting, executing, completed, failed

    public var label: String {
        switch self {
        case .pending: return "Pending"
        case .connecting: return "Connecting"
        case .executing: return "Executing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    public var color: Color {
        switch self {
        case .pending: return .gray
        case .connecting: return .orange
        case .executing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    public var systemImage: String {
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

public enum MCPError: LocalizedError, Codable {
    case invalidURL
    case authenticationFailed(String)
    case connectionFailed(String)
    case serverError(code: Int, message: String, data: AnyCodable?)
    case toolNotFound(String)
    case invalidResponse(String)
    case timeout
    case decodeError(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "The server URL is invalid."
        case .authenticationFailed(let reason): return "Authentication failed: \(reason)"
        case .connectionFailed(let reason): return "Connection failed: \(reason)"
        case .serverError(let code, let message, _): return "Server error (\(code)): \(message)"
        case .toolNotFound(let name): return "Tool '\(name)' not found."
        case .invalidResponse(let detail): return "Invalid response: \(detail)"
        case .timeout: return "The request timed out."
        case .decodeError(let detail): return "Failed to decode response: \(detail)"
        case .unknown(let detail): return "An unknown error occurred: \(detail)"
        }
    }
}
