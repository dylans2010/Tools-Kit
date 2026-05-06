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
        let authURL = try await SDKAuthManager.shared.initiateOAuthFlow(for: id, provider: "google")
        // In a real app, ASWebAuthenticationSession would handle this
        SDKLogStore.shared.log("Initiated OAuth flow: \(authURL)", source: "GmailConnector", level: .info)
        status = .connected
        log("Authenticated successfully", level: .info)
    }

    public func sync() async throws {
        guard status == .connected else { return }
        log("Syncing emails from Gmail API...", level: .info)
        let messages = WorkspaceAPI.shared.mail.listMessages()
        log("Synced \(messages.count) messages", level: .info)
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
