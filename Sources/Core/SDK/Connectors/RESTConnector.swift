import Foundation
import Combine

public final class RESTConnector: BaseConnector {
    public let id = UUID()
    public let name = "REST API"
    public let type: ConnectorType = .rest
    public let requiredScopes: [String] = ["external.api.unrestricted"]
    @Published public var status: ConnectorStatus = .disconnected

    public var authFields: [AuthField] {
        [
            AuthField(label: "Base URL", placeholder: "https://api.example.com", isSecure: false, key: "baseUrl"),
            AuthField(label: "API Key", placeholder: "Enter API Key", isSecure: true, key: "apiKey"),
            AuthField(label: "Auth Header", placeholder: "Authorization", isSecure: false, key: "authHeader"),
            AuthField(label: "Auth Prefix", placeholder: "Bearer", isSecure: false, key: "authPrefix")
        ]
    }

    @Published public var activityLog: [ConnectorEvent] = []

    private var config: [String: String] = [:]
    private var tokenExpiresAt: Date?

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        guard let baseUrl = credentials["baseUrl"], !baseUrl.isEmpty else {
            throw SDKConnectorError.invalidConfiguration(connector: name, field: "baseUrl")
        }
        guard URL(string: baseUrl) != nil else {
            throw SDKConnectorError.invalidConfiguration(connector: name, field: "baseUrl")
        }

        config = credentials
        status = .connecting
        log("Configuring REST connector for \(baseUrl)", level: .info)

        let connected = try await testConnection()
        if connected {
            status = .connected
            log("REST connected to \(baseUrl)", level: .info)
        } else {
            status = .error
            throw SDKConnectorError.connectionFailed(connector: name, reason: "Base URL not reachable")
        }
    }

    public func sync() async throws {
        guard status == .connected else {
            throw SDKConnectorError.disconnected(connector: name)
        }

        if let expiresAt = tokenExpiresAt, Date() > expiresAt {
            log("Token expired, attempting refresh", level: .warning)
            try await refreshAuth()
        }

        log("REST sync (health check)...", level: .info)
        _ = try await testConnection()
    }

    public func testConnection() async throws -> Bool {
        guard let baseUrl = config["baseUrl"], let url = URL(string: baseUrl) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        applyAuth(to: &request)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return (200...499).contains(httpResponse.statusCode)
    }

    public func disconnect() {
        status = .disconnected
        config.removeAll()
        tokenExpiresAt = nil
        log("REST disconnected", level: .info)
    }

    public func execute(path: String, method: String = "GET", headers: [String: String] = [:], body: Data? = nil) async throws -> (Int, Data) {
        guard status == .connected else { throw SDKConnectorError.disconnected(connector: name) }
        guard let baseUrl = config["baseUrl"], let url = URL(string: baseUrl + path) else {
            throw SDKConnectorError.invalidConfiguration(connector: name, field: "baseUrl")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 30
        applyAuth(to: &request)
        for (k, v) in headers { request.addValue(v, forHTTPHeaderField: k) }
        if body != nil && request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        log("\(method) \(path) -> \(code)", level: (200..<400).contains(code) ? .info : .warning)
        return (code, data)
    }

    private func refreshAuth() async throws {
        guard let refreshURL = config["refreshUrl"], let url = URL(string: refreshURL) else {
            status = .error
            throw SDKConnectorError.authenticationFailed(connector: name)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResp = response as? HTTPURLResponse, (200..<300).contains(httpResp.statusCode) else {
            status = .error
            throw SDKConnectorError.authenticationFailed(connector: name)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let newToken = json["access_token"] as? String {
            config["apiKey"] = newToken
            if let expiresIn = json["expires_in"] as? TimeInterval {
                tokenExpiresAt = Date().addingTimeInterval(expiresIn)
            }
            log("Token refreshed", level: .info)
        }
    }

    private func applyAuth(to request: inout URLRequest) {
        let header = config["authHeader"] ?? "Authorization"
        let prefix = config["authPrefix"] ?? "Bearer"
        if let apiKey = config["apiKey"], !apiKey.isEmpty {
            request.addValue("\(prefix) \(apiKey)", forHTTPHeaderField: header)
        }
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "RESTConnector", level: level)
        }
    }
}
