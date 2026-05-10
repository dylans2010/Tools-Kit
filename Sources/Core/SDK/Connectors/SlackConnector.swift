// ToolsKit — SlackConnector.swift
// SDK Expansion — Phase 4

import Foundation
import Combine

/// Connector for Slack workspace integration.
public final class SlackConnector: BaseConnector {
    public let id = UUID()
    public let name = "Slack"
    public let type: ConnectorType = .webhook
    public let requiredScopes: [String] = ["external.api.slack", "workspace.messaging"]
    @Published public var status: ConnectorStatus = .disconnected

    public var authFields: [AuthField] {
        [
            AuthField(label: "Bot Token", placeholder: "xoxb-...", isSecure: true, key: "botToken"),
            AuthField(label: "Channel ID", placeholder: "C0123456789", isSecure: false, key: "channelId"),
            AuthField(label: "Webhook URL", placeholder: "https://hooks.slack.com/...", isSecure: true, key: "webhookUrl")
        ]
    }

    @Published public var activityLog: [ConnectorEvent] = []

    private var config: [String: String] = [:]
    private var lastMessageTimestamp: String?

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        guard let token = credentials["botToken"], !token.isEmpty else {
            throw SDKConnectorError.invalidConfiguration(connector: name, field: "botToken")
        }

        config = credentials
        status = .connecting

        let isValid = try await validateToken(token)
        if isValid {
            status = .connected
            log("Slack connected successfully", level: .info)
        } else {
            status = .error
            throw SDKConnectorError.authenticationFailed(connector: name)
        }
    }

    public func sync() async throws {
        guard status == .connected else {
            throw SDKConnectorError.disconnected(connector: name)
        }

        log("Syncing Slack messages...", level: .info)

        guard let token = config["botToken"],
              let channelId = config["channelId"] else {
            throw SDKConnectorError.invalidConfiguration(connector: name, field: "channelId")
        }

        var urlComponents = URLComponents(string: "https://slack.com/api/conversations.history")
        urlComponents?.queryItems = [
            URLQueryItem(name: "channel", value: channelId),
            URLQueryItem(name: "limit", value: "20")
        ]

        guard let url = urlComponents?.url else {
            throw SDKConnectorError.connectionFailed(connector: name, reason: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SDKConnectorError.connectionFailed(connector: name, reason: "No HTTP response")
        }

        if (200...299).contains(httpResponse.statusCode) {
            log("Slack sync completed", level: .info)
        } else {
            log("Slack sync failed: HTTP \(httpResponse.statusCode)", level: .error)
            throw SDKConnectorError.syncFailed(connector: name, reason: "HTTP \(httpResponse.statusCode)")
        }
    }

    public func testConnection() async throws -> Bool {
        guard let token = config["botToken"], !token.isEmpty else { return false }

        guard let url = URL(string: "https://slack.com/api/auth.test") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return false
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ok = json["ok"] as? Bool {
            return ok
        }

        return false
    }

    public func disconnect() {
        status = .disconnected
        config.removeAll()
        log("Slack disconnected", level: .info)
    }

    public func sendMessage(text: String, channel: String? = nil) async throws {
        guard status == .connected else {
            throw SDKConnectorError.disconnected(connector: name)
        }

        if let webhookUrl = config["webhookUrl"], !webhookUrl.isEmpty {
            try await sendViaWebhook(text: text, webhookUrl: webhookUrl)
        } else if let token = config["botToken"] {
            let targetChannel = channel ?? config["channelId"] ?? ""
            try await sendViaAPI(text: text, channel: targetChannel, token: token)
        } else {
            throw SDKConnectorError.invalidConfiguration(connector: name, field: "webhookUrl or botToken")
        }

        log("Message sent to Slack", level: .info)
    }

    private func validateToken(_ token: String) async throws -> Bool {
        guard let url = URL(string: "https://slack.com/api/auth.test") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ok = json["ok"] as? Bool {
            return ok
        }
        return false
    }

    private func sendViaWebhook(text: String, webhookUrl: String) async throws {
        guard let url = URL(string: webhookUrl) else {
            throw SDKConnectorError.invalidConfiguration(connector: name, field: "webhookUrl")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: String] = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SDKConnectorError.syncFailed(connector: name, reason: "Webhook delivery failed")
        }
    }

    private func sendViaAPI(text: String, channel: String, token: String) async throws {
        guard let url = URL(string: "https://slack.com/api/chat.postMessage") else {
            throw SDKConnectorError.connectionFailed(connector: name, reason: "Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: String] = ["channel": channel, "text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SDKConnectorError.syncFailed(connector: name, reason: "API message send failed")
        }
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "SlackConnector", level: level)
        }
    }
}
