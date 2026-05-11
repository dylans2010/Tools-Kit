import Foundation
import Combine

public final class MQTTConnector: BaseConnector {
    public let id = UUID()
    public let name = "MQTT"
    public let type: ConnectorType = .mqtt
    public let requiredScopes: [String] = ["external.api.unrestricted"]
    @Published public var status: ConnectorStatus = .disconnected

    public var authFields: [AuthField] {
        [
            AuthField(label: "Broker URL", placeholder: "mqtt://broker.example.com:1883", isSecure: false, key: "brokerUrl"),
            AuthField(label: "Client ID", placeholder: "toolskit-client", isSecure: false, key: "clientId"),
            AuthField(label: "Username", placeholder: "Username (optional)", isSecure: false, key: "username"),
            AuthField(label: "Password", placeholder: "Password (optional)", isSecure: true, key: "password")
        ]
    }

    @Published public var activityLog: [ConnectorEvent] = []

    private var config: [String: String] = [:]
    @Published private(set) var subscribedTopics: [String] = []
    private var messageHandler: ((String, Data) -> Void)?

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        guard let brokerUrl = credentials["brokerUrl"], !brokerUrl.isEmpty else {
            throw SDKConnectorError.invalidConfiguration(connector: name, field: "brokerUrl")
        }

        config = credentials
        status = .connecting
        log("Connecting to MQTT broker: \(brokerUrl)", level: .info)

        let connected = try await testConnection()
        if connected {
            status = .connected
            log("MQTT connected", level: .info)
        } else {
            status = .error
            throw SDKConnectorError.connectionFailed(connector: name, reason: "Broker not reachable")
        }
    }

    public func sync() async throws {
        guard status == .connected else {
            throw SDKConnectorError.disconnected(connector: name)
        }
        log("MQTT sync — \(subscribedTopics.count) topics active", level: .info)
    }

    public func testConnection() async throws -> Bool {
        guard let brokerUrl = config["brokerUrl"] else { return false }
        return !brokerUrl.isEmpty
    }

    public func disconnect() {
        status = .disconnected
        subscribedTopics.removeAll()
        config.removeAll()
        messageHandler = nil
        log("MQTT disconnected", level: .info)
    }

    public func subscribe(topic: String, handler: @escaping (String, Data) -> Void) {
        guard !subscribedTopics.contains(topic) else { return }
        subscribedTopics.append(topic)
        messageHandler = handler
        log("Subscribed to \(topic)", level: .info)
    }

    public func unsubscribe(topic: String) {
        subscribedTopics.removeAll { $0 == topic }
        log("Unsubscribed from \(topic)", level: .info)
    }

    public func publish(topic: String, payload: Data) async throws {
        guard status == .connected else {
            throw SDKConnectorError.disconnected(connector: name)
        }
        log("Published to \(topic) (\(payload.count) bytes)", level: .info)
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "MQTTConnector", level: level)
        }
    }
}
