import Foundation
import Combine

public final class GitHubConnector: BaseConnector {
    public let id = UUID()
    public let name = "GitHub"
    public let type: ConnectorType = .github
    @Published public var status: ConnectorStatus = .disconnected

    public var authFields: [AuthField] {
        [AuthField(label: "Personal Access Token", placeholder: "ghp_...", isSecure: true, key: "token")]
    }

    @Published public var activityLog: [ConnectorEvent] = []
    private var token: String?

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        guard let token = credentials["token"] else { throw SDKError.executionFailed(reason: "Missing token") }
        self.token = token
        status = .connected
        log("GitHub Authenticated", level: .info)
    }

    public func sync() async throws {
        log("Syncing repos...", level: .info)
        // Mock sync
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        log("Synced 3 repositories", level: .info)
    }

    public func testConnection() async throws -> Bool {
        return token != nil
    }

    public func disconnect() {
        status = .disconnected
        token = nil
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "GitHubConnector", level: level)
        }
    }
}
