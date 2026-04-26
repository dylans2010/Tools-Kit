import Foundation

struct GitHubWorkflow: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let path: String
    let state: String
    let createdAt: Date
    let updatedAt: Date
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case id, name, path, state
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case htmlURL = "html_url"
    }
}

struct WorkflowListResponse: Codable, Sendable {
    let totalCount: Int
    let workflows: [GitHubWorkflow]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case workflows
    }
}

struct GitHubWorkflowRun: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String?
    let headBranch: String
    let headSHA: String
    let runNumber: Int
    let event: String
    let status: String?
    let conclusion: String?
    let workflowID: Int
    let htmlURL: URL
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, event, status, conclusion
        case headBranch = "head_branch"
        case headSHA = "head_sha"
        case runNumber = "run_number"
        case workflowID = "workflow_id"
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WorkflowRunListResponse: Codable, Sendable {
    let totalCount: Int
    let workflowRuns: [GitHubWorkflowRun]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case workflowRuns = "workflow_runs"
    }
}

struct WorkflowArtifact: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let sizeInBytes: Int
    let archiveDownloadURL: URL
    let expired: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, expired
        case sizeInBytes = "size_in_bytes"
        case archiveDownloadURL = "archive_download_url"
        case createdAt = "created_at"
    }
}

struct WorkflowArtifactListResponse: Codable, Sendable {
    let totalCount: Int
    let artifacts: [WorkflowArtifact]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case artifacts
    }
}

struct WorkflowJob: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let status: String?
    let conclusion: String?
    let startedAt: Date?
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, status, conclusion
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

struct WorkflowJobsResponse: Codable, Sendable {
    let totalCount: Int
    let jobs: [WorkflowJob]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case jobs
    }
}

struct WorkflowDispatchRequest: Encodable, Sendable {
    let ref: String
    let inputs: [String: String]?
}

struct WorkflowFileDefinition: Sendable {
    let name: String
    let path: String
    let content: String
}

struct WorkflowTemplate: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let category: String
    let description: String
    let yaml: String
    let version: String
}

struct WorkflowSummary: Identifiable, Hashable, Sendable {
    var id: Int { workflow.id }
    let workflow: GitHubWorkflow
    let lastRun: GitHubWorkflowRun?
    let isFavorite: Bool

    var triggerDescription: String {
        if workflow.path.contains("workflow_dispatch") { return "manual" }
        return "path-driven"
    }
}

struct WorkflowAnalytics: Hashable, Sendable {
    let totalRuns: Int
    let successfulRuns: Int
    let failedRuns: Int
    let successRate: Double
    let averageDurationSeconds: TimeInterval
}

struct WorkflowGenerationRequest: Sendable {
    let prompt: String
    let owner: String
    let repo: String
    let branch: String
    let workflowName: String
    let triggerImmediately: Bool
}

struct WorkflowGenerationResult: Sendable {
    let workflowPath: String
    let commitSHA: String
    let runID: Int?
}
