import Foundation

actor WorkflowLogStreamer {
    private let client: GitHubActionsClient

    init(client: GitHubActionsClient = GitHubActionsClient()) {
        self.client = client
    }

    func downloadLogArchive(owner: String, repo: String, runID: Int) async throws -> URL {
        let data = try await client.downloadLogs(owner: owner, repo: repo, runID: runID)
        let fileName = "run-\(runID)-logs.zip"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    func readLogText(owner: String, repo: String, runID: Int) async throws -> String {
        let data = try await client.downloadLogs(owner: owner, repo: repo, runID: runID)
        let text = String(data: data, encoding: .utf8) ?? "Binary log archive downloaded (\(data.count) bytes)."
        return parse(text: text)
    }

    private func parse(text: String) -> String {
        text
            .replacingOccurrences(of: "\u{001B}[0;31m", with: "")
            .replacingOccurrences(of: "\u{001B}[0m", with: "")
    }

    func extractFailureReasons(from text: String) -> [String] {
        text
            .split(separator: "\n")
            .map(String.init)
            .filter { $0.localizedCaseInsensitiveContains("error") || $0.localizedCaseInsensitiveContains("failed") }
            .prefix(20)
            .map { $0 }
    }
}
