import Foundation
import Combine

public final class WebhookConnector: BaseConnector {
    public let id = UUID()
    public let name = "Webhook"
    public let type: ConnectorType = .webhook
    @Published public var status: ConnectorStatus = .disconnected

    public var authFields: [AuthField] {
        [
            AuthField(label: "URL", placeholder: "https://api.example.com/webhook", isSecure: false, key: "url"),
            AuthField(label: "API Key", placeholder: "Enter API Key", isSecure: true, key: "apiKey")
        ]
    }

    @Published public var activityLog: [ConnectorEvent] = []
    private var config: [String: String] = [:]

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        self.config = credentials
        status = .connected
        log("Webhook configured", level: LogLevel.info)
    }

    public func sync() async throws {
        log("Checking webhook health...", level: LogLevel.info)
        _ = try await testConnection()
    }

    public func execute(payload: [String: Any]) async throws -> Data {
        guard let urlString = config["url"], let url = URL(string: urlString) else {
            throw SDKError.executionFailed(reason: "Invalid Webhook URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = config["apiKey"] {
            request.addValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw SDKError.executionFailed(reason: "Webhook failed with status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        return data
    }

    public func testConnection() async throws -> Bool {
        guard let urlString = config["url"], let url = URL(string: urlString) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    public func disconnect() {
        status = .disconnected
        config.removeAll()
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "WebhookConnector", level: level)
        }
    }
}
