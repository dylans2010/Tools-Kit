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
        return "Downloaded \(data.count) bytes of logs for run #\(runID)."
    }
}
