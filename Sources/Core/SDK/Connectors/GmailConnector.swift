import Foundation
import Combine
import AuthenticationServices

public final class GmailConnector: BaseConnector {
    public let id = UUID()
    public let name = "Gmail"
    public let type: ConnectorType = .gmail
    @Published public var status: ConnectorStatus = .disconnected

    public var authFields: [AuthField] {
        [AuthField(label: "OAuth2", placeholder: "Click to Authorize", isSecure: false, key: "oauth")]
    }

    @Published public var activityLog: [ConnectorEvent] = []

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        status = .connecting
        // Simulate OAuth2
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        status = .connected
        log("Authenticated successfully", level: .info)
    }

    public func sync() async throws {
        guard status == .connected else { return }
        log("Syncing emails...", level: .info)
        // Mock fetch
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        log("Synced 5 new messages", level: .info)
    }

    public func testConnection() async throws -> Bool {
        return status == .connected
    }

    public func disconnect() {
        status = .disconnected
        log("Disconnected", level: .info)
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "GmailConnector", level: level)
        }
    }
}
