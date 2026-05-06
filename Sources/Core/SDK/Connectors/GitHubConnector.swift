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
        log("Syncing repositories from GitHub API...", level: .info)

        guard let token = self.token else {
            throw SDKError.executionFailed(reason: "Missing GitHub token")
        }

        let request = SDKRequestBuilder()
            .setEndpoint("https://api.github.com/user/repos")
            .addHeader("Authorization", value: "Bearer \(token)")
            .addHeader("Accept", value: "application/vnd.github.v3+json")
            .build()

        guard let request = request else { throw SDKError.executionFailed(reason: "Failed to build request") }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw SDKError.executionFailed(reason: "GitHub API returned status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        let nodes = SDKResponseParser.shared.mapToDataNodes(["raw": data], scope: .files)
        log("Synced \(nodes.count) repositories", level: .info)
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
