import Foundation
import Combine
import AuthenticationServices

public final class GmailConnector: BaseConnector {
    public let id = UUID()
    public let name = "Gmail"
    public let type: ConnectorType = .gmail
    public let requiredScopes: [String] = ["external.api.unrestricted", "workspace.mail.read"]
    @Published public var status: ConnectorStatus = .disconnected

    public var authFields: [AuthField] {
        [AuthField(label: "OAuth2", placeholder: "Click to Authorize", isSecure: false, key: "oauth")]
    }

    @Published public var activityLog: [ConnectorEvent] = []
    private var accessToken: String?
    private var refreshToken: String?

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        status = .connecting
        log("Initiating Gmail OAuth2 authentication...", level: LogLevel.info)

        guard let token = credentials["oauth"] ?? credentials["token"] else {
            status = .error
            log("OAuth2 token not provided", level: LogLevel.error)
            throw SDKError.executionFailed(reason: "Gmail OAuth2 token required")
        }

        accessToken = token
        refreshToken = credentials["refresh_token"]

        let isValid = try await validateToken(token)
        if isValid {
            status = .connected
            log("Gmail authenticated successfully", level: LogLevel.info)
        } else {
            status = .error
            log("Gmail authentication failed: invalid token", level: LogLevel.error)
            throw SDKError.executionFailed(reason: "Gmail OAuth2 token validation failed")
        }
    }

    public func sync() async throws {
        guard status == .connected, let token = accessToken else {
            throw SDKError.executionFailed(reason: "Gmail not connected")
        }

        log("Syncing Gmail messages...", level: LogLevel.info)

        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=10")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SDKError.executionFailed(reason: "Invalid Gmail API response")
        }

        if httpResponse.statusCode == 401 {
            status = .error
            log("Gmail token expired, re-authentication required", level: LogLevel.error)
            throw SDKError.executionFailed(reason: "Gmail token expired")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            log("Gmail sync failed with status \(httpResponse.statusCode)", level: LogLevel.error)
            throw SDKError.executionFailed(reason: "Gmail API error: HTTP \(httpResponse.statusCode)")
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let messages = json["messages"] as? [[String: Any]] {
            log("Synced \(messages.count) Gmail messages", level: LogLevel.info)
        } else {
            log("Gmail sync completed (no new messages)", level: LogLevel.info)
        }
    }

    public func testConnection() async throws -> Bool {
        guard let token = accessToken else { return false }
        return await validateTokenSilent(token)
    }

    public func disconnect() {
        status = .disconnected
        accessToken = nil
        refreshToken = nil
        log("Gmail disconnected", level: LogLevel.info)
    }

    private func validateToken(_ token: String) async throws -> Bool {
        let url = URL(string: "https://oauth2.googleapis.com/tokeninfo?access_token=\(token)")!
        let (_, response) = try await URLSession.shared.data(from: url)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    private func validateTokenSilent(_ token: String) async -> Bool {
        do {
            return try await validateToken(token)
        } catch {
            return false
        }
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "GmailConnector", level: level)
        }
    }
}
