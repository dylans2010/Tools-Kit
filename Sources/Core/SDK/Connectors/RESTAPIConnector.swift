// ToolsKit — RESTAPIConnector.swift
// SDK Expansion — Phase 4

import Foundation
import Combine

/// Generic REST API connector for arbitrary HTTP endpoints.
public final class RESTAPIConnector: BaseConnector {
    public let id = UUID()
    public let name = "REST API"
    public let type: ConnectorType = .webhook
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
        log("Configuring REST API connector for \(baseUrl)", level: .info)

        let connected = try await testConnection()
        if connected {
            status = .connected
            log("REST API connected to \(baseUrl)", level: .info)
        } else {
            status = .error
            throw SDKConnectorError.connectionFailed(connector: name, reason: "Base URL not reachable")
        }
    }

    public func sync() async throws {
        guard status == .connected else {
            throw SDKConnectorError.disconnected(connector: name)
        }
        log("REST API sync (health check)...", level: .info)
        _ = try await testConnection()
    }

    public func testConnection() async throws -> Bool {
        guard let baseUrl = config["baseUrl"], let url = URL(string: baseUrl) else {
            return false
        }

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
        log("REST API disconnected", level: .info)
    }

    /// Execute a REST request against the configured API.
    public func execute(
        path: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> RESTAPIResponse {
        guard status == .connected else {
            throw SDKConnectorError.disconnected(connector: name)
        }

        guard let baseUrl = config["baseUrl"],
              let url = URL(string: baseUrl + path) else {
            throw SDKConnectorError.invalidConfiguration(connector: name, field: "baseUrl")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 30

        applyAuth(to: &request)

        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }

        if body != nil && request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let latency = Date().timeIntervalSince(startTime)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SDKConnectorError.connectionFailed(connector: name, reason: "No HTTP response")
        }

        let apiResponse = RESTAPIResponse(
            statusCode: httpResponse.statusCode,
            data: data,
            headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
            latency: latency
        )

        SDKConnectorMetricsTracker.shared.recordRequest(
            connectorID: id,
            duration: latency,
            success: apiResponse.isSuccess
        )

        log("\(method) \(path) → \(httpResponse.statusCode) (\(String(format: "%.0f", latency * 1000))ms)", level: apiResponse.isSuccess ? .info : .warning)

        return apiResponse
    }

    private func applyAuth(to request: inout URLRequest) {
        guard let apiKey = config["apiKey"], !apiKey.isEmpty else { return }
        let header = config["authHeader"] ?? "Authorization"
        let prefix = config["authPrefix"] ?? "Bearer"
        let value = prefix.isEmpty ? apiKey : "\(prefix) \(apiKey)"
        request.addValue(value, forHTTPHeaderField: header)
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "RESTAPIConnector", level: level)
        }
    }
}

/// Response from a REST API call.
public struct RESTAPIResponse: Sendable {
    public let statusCode: Int
    public let data: Data
    public let headers: [String: String]
    public let latency: TimeInterval

    public var isSuccess: Bool {
        (200...299).contains(statusCode)
    }

    public var bodyString: String {
        String(data: data, encoding: .utf8) ?? ""
    }

    public func decoded<T: Decodable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }

    public init(statusCode: Int, data: Data, headers: [String: String], latency: TimeInterval) {
        self.statusCode = statusCode
        self.data = data
        self.headers = headers
        self.latency = latency
    }
}
