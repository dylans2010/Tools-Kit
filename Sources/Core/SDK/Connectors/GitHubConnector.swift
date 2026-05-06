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
    private var authenticatedUser: String?

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        guard let token = credentials["token"], !token.isEmpty else {
            throw SDKError.executionFailed(reason: "GitHub Personal Access Token required")
        }

        status = .connecting
        log("Authenticating with GitHub...", level: .info)

        self.token = token

        let url = URL(string: "https://api.github.com/user")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            status = .error
            throw SDKError.executionFailed(reason: "Invalid GitHub API response")
        }

        guard httpResponse.statusCode == 200 else {
            status = .error
            log("GitHub auth failed: HTTP \(httpResponse.statusCode)", level: .error)
            throw SDKError.executionFailed(reason: "GitHub authentication failed: HTTP \(httpResponse.statusCode)")
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let login = json["login"] as? String {
            authenticatedUser = login
            log("GitHub authenticated as \(login)", level: .info)
        }

        status = .connected
    }

    public func sync() async throws {
        guard status == .connected, let token = token else {
            throw SDKError.executionFailed(reason: "GitHub not connected")
        }

        log("Syncing GitHub repositories...", level: .info)

        let url = URL(string: "https://api.github.com/user/repos?sort=updated&per_page=10")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            log("GitHub sync failed: HTTP \(statusCode)", level: .error)
            throw SDKError.executionFailed(reason: "GitHub API error: HTTP \(statusCode)")
        }

        if let repos = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            log("Synced \(repos.count) repositories", level: .info)
        }
    }

    public func testConnection() async throws -> Bool {
        guard let token = token else { return false }

        let url = URL(string: "https://api.github.com/user")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    public func disconnect() {
        status = .disconnected
        token = nil
        authenticatedUser = nil
        log("GitHub disconnected", level: .info)
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "GitHubConnector", level: level)
        }
    }
}
