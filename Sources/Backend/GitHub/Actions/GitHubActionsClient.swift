import Foundation

actor GitHubActionsClient {
    enum ActionsError: LocalizedError {
        case missingToken
        case invalidResponse
        case unexpectedStatusCode(Int, String)

        var errorDescription: String? {
            switch self {
            case .missingToken:
                return "A GitHub token is required."
            case .invalidResponse:
                return "Received an invalid response from GitHub."
            case .unexpectedStatusCode(let code, let message):
                return "GitHub API returned status \(code): \(message)"
            }
        }
    }

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let maxRetries = 3

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    private func request(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        acceptedStatusCodes: ClosedRange<Int> = 200...299
    ) async throws -> Data {
        guard let token = GitHubAuthManager.shared.getToken() else {
            throw ActionsError.missingToken
        }

        let url = URL(string: "https://api.github.com\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Tools-Kit-iOS", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encode(body)
        }

        var attempt = 0
        var latestError: Error?

        while attempt < maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                try Task.checkCancellation()

                guard let http = response as? HTTPURLResponse else {
                    throw ActionsError.invalidResponse
                }

                if acceptedStatusCodes.contains(http.statusCode) {
                    return data
                }

                if http.statusCode >= 500 || http.statusCode == 429 {
                    attempt += 1
                    if attempt < maxRetries {
                        try await Task.sleep(for: .seconds(Double(attempt)))
                        continue
                    }
                }

                let message = String(data: data, encoding: .utf8) ?? "No details"
                throw ActionsError.unexpectedStatusCode(http.statusCode, message)
            } catch {
                latestError = error
                attempt += 1
                if error is CancellationError {
                    throw error
                }
                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(Double(attempt)))
                }
            }
        }

        throw latestError ?? ActionsError.invalidResponse
    }

    private func encode(_ body: any Encodable) throws -> Data {
        let wrapped = AnyEncodable(body)
        return try encoder.encode(wrapped)
    }

    func listWorkflows(owner: String, repo: String) async throws -> [GitHubWorkflow] {
        let data = try await request(path: "/repos/\(owner)/\(repo)/actions/workflows")
        return try decoder.decode(WorkflowListResponse.self, from: data).workflows
    }

    func dispatchWorkflow(owner: String, repo: String, workflowID: String, ref: String, inputs: [String: String]?) async throws {
        let cleanedRef = ref.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedRef.isEmpty else {
            throw ActionsError.unexpectedStatusCode(400, "Invalid ref field. Ref must be non-empty.")
        }
        let cleanedInputs = inputs?.filter { !$0.key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let payload = WorkflowDispatchRequest(ref: cleanedRef, inputs: cleanedInputs?.isEmpty == true ? nil : cleanedInputs)
        _ = try await request(
            path: "/repos/\(owner)/\(repo)/actions/workflows/\(workflowID)/dispatches",
            method: "POST",
            body: payload,
            acceptedStatusCodes: 204...204
        )
    }

    func listRuns(owner: String, repo: String, workflowID: Int? = nil) async throws -> [GitHubWorkflowRun] {
        let path: String
        if let workflowID {
            path = "/repos/\(owner)/\(repo)/actions/workflows/\(workflowID)/runs"
        } else {
            path = "/repos/\(owner)/\(repo)/actions/runs"
        }

        let data = try await request(path: path)
        return try decoder.decode(WorkflowRunListResponse.self, from: data).workflowRuns
    }

    func getRun(owner: String, repo: String, runID: Int) async throws -> GitHubWorkflowRun {
        let data = try await request(path: "/repos/\(owner)/\(repo)/actions/runs/\(runID)")
        return try decoder.decode(GitHubWorkflowRun.self, from: data)
    }

    func listArtifacts(owner: String, repo: String, runID: Int) async throws -> [WorkflowArtifact] {
        let data = try await request(path: "/repos/\(owner)/\(repo)/actions/runs/\(runID)/artifacts")
        return try decoder.decode(WorkflowArtifactListResponse.self, from: data).artifacts
    }

    func listJobs(owner: String, repo: String, runID: Int) async throws -> [WorkflowJob] {
        let data = try await request(path: "/repos/\(owner)/\(repo)/actions/runs/\(runID)/jobs")
        return try decoder.decode(WorkflowJobsResponse.self, from: data).jobs
    }

    func downloadLogs(owner: String, repo: String, runID: Int) async throws -> Data {
        try await request(path: "/repos/\(owner)/\(repo)/actions/runs/\(runID)/logs", acceptedStatusCodes: 200...302)
    }

    func rerun(runID: Int, owner: String, repo: String) async throws {
        _ = try await request(
            path: "/repos/\(owner)/\(repo)/actions/runs/\(runID)/rerun",
            method: "POST",
            acceptedStatusCodes: 201...201
        )
    }

    func cancel(runID: Int, owner: String, repo: String) async throws {
        _ = try await request(
            path: "/repos/\(owner)/\(repo)/actions/runs/\(runID)/cancel",
            method: "POST",
            acceptedStatusCodes: 202...202
        )
    }

    func setWorkflowState(owner: String, repo: String, workflowID: Int, enabled: Bool) async throws {
        let path = "/repos/\(owner)/\(repo)/actions/workflows/\(workflowID)/\(enabled ? "enable" : "disable")"
        _ = try await request(path: path, method: "PUT", acceptedStatusCodes: 200...204)
    }



    func getWorkflowYAML(owner: String, repo: String, path: String, ref: String) async throws -> String {
        let data = try await request(path: "/repos/\(owner)/\(repo)/contents/\(path)?ref=\(ref)")
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = object["content"] as? String
        else {
            throw ActionsError.invalidResponse
        }
        let compact = content.replacingOccurrences(of: "\n", with: "")
        guard let decoded = Data(base64Encoded: compact), let text = String(data: decoded, encoding: .utf8) else {
            throw ActionsError.invalidResponse
        }
        return text
    }

    func downloadArtifact(owner: String, repo: String, artifactID: Int) async throws -> Data {
        try await request(path: "/repos/\(owner)/\(repo)/actions/artifacts/\(artifactID)/zip", acceptedStatusCodes: 200...302)
    }
    func putFile(
        owner: String,
        repo: String,
        path: String,
        message: String,
        content: String,
        branch: String,
        sha: String?
    ) async throws -> String {
        struct FilePayload: Encodable, Sendable {
            let message: String
            let content: String
            let branch: String
            let sha: String?
        }
        struct FileResponse: Codable, Sendable {
            struct Commit: Codable, Sendable { let sha: String }
            let commit: Commit
        }

        let payload = FilePayload(message: message, content: content, branch: branch, sha: sha)
        let data = try await request(path: "/repos/\(owner)/\(repo)/contents/\(path)", method: "PUT", body: payload)
        return try decoder.decode(FileResponse.self, from: data).commit.sha
    }

    func getContentSHA(owner: String, repo: String, path: String, ref: String) async throws -> String? {
        let data = try await request(path: "/repos/\(owner)/\(repo)/contents/\(path)?ref=\(ref)")
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return object?["sha"] as? String
    }
}

private struct AnyEncodable: Encodable {
    private let encoder: (Encoder) throws -> Void

    init(_ wrapped: some Encodable) {
        self.encoder = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try self.encoder(encoder)
    }
}
