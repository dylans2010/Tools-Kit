import Foundation

/// Represents a Jules session.
struct AgentSession: Codable, Identifiable {
    let id: String
    let name: String
    let title: String?
    let prompt: String?
    let status: String?
    let sessionURL: String?
    let sourceContext: AgentSourceContext
    let outputs: [AgentOutput]?

    enum CodingKeys: String, CodingKey {
        case id, name, title, prompt, status, outputs
        case sourceContext = "sourceContext"
        case sessionURL = "session_url"
    }

    private enum LegacySessionURLKeys: String, CodingKey {
        case webURL = "web_url"
        case htmlURL = "html_url"
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? id
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        prompt = try? container.decodeIfPresent(String.self, forKey: .prompt)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
        let legacyContainer = try decoder.container(keyedBy: LegacySessionURLKeys.self)
        sessionURL = (try? container.decodeIfPresent(String.self, forKey: .sessionURL))
            ?? (try? legacyContainer.decodeIfPresent(String.self, forKey: .webURL))
            ?? (try? legacyContainer.decodeIfPresent(String.self, forKey: .htmlURL))
            ?? (try? legacyContainer.decodeIfPresent(String.self, forKey: .url))
        sourceContext = (try? container.decode(AgentSourceContext.self, forKey: .sourceContext)) ?? AgentSourceContext(source: "unknown", githubRepoContext: nil)
        outputs = try? container.decodeIfPresent([AgentOutput].self, forKey: .outputs)
    }
}

struct AgentSourceContext: Codable {
    let source: String
    let githubRepoContext: AgentGitHubRepoContext?
}

struct AgentGitHubRepoContext: Codable {
    let startingBranch: String?
}

struct AgentOutput: Codable {
    let prURL: String?
    let pullRequest: AgentPullRequest?

    enum CodingKeys: String, CodingKey {
        case prURL = "pr_url"
        case pullRequest = "pull_request"
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case pullRequest = "pullRequest"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
        prURL = try? container.decodeIfPresent(String.self, forKey: .prURL)
        pullRequest = (try? container.decodeIfPresent(AgentPullRequest.self, forKey: .pullRequest))
            ?? (try? legacyContainer.decodeIfPresent(AgentPullRequest.self, forKey: .pullRequest))
    }
}

struct AgentPullRequest: Codable {
    let url: String
    let title: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case url
        case title
        case description
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case htmlURL = "html_url"
        case body
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
        url = (try? container.decode(String.self, forKey: .url))
            ?? (try? legacyContainer.decode(String.self, forKey: .htmlURL))
            ?? ""
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        description = (try? container.decodeIfPresent(String.self, forKey: .description))
            ?? (try? legacyContainer.decodeIfPresent(String.self, forKey: .body))
    }
}

/// Represents an activity within a Jules session.
struct AgentActivity: Codable, Identifiable {
    let id: String
    let name: String
    let createTime: Date
    let originator: String // "agent" or "user"
    let planGenerated: AgentPlanGenerated?
    let progressUpdated: AgentProgressUpdated?
    let sessionCompleted: AgentSessionCompleted?
    let toolExecuted: AgentToolExecution?
    let memoryUpdated: AgentMemoryEntry?
    let checkpointCreated: AgentCheckpoint?
    let diffGenerated: AgentDiff?
    let timelineUpdated: AgentTimelineStep?

    enum CodingKeys: String, CodingKey {
        case id, name, createTime, originator
        case planGenerated, progressUpdated, sessionCompleted
        case toolExecuted, memoryUpdated, checkpointCreated, diffGenerated, timelineUpdated
    }
}

struct AgentToolExecution: Codable, Identifiable {
    var id: String { requestId }
    let tool: String
    let status: String
    let requestId: String
    let input: [String: AnyCodable]
    let output: [String: AnyCodable]
    let error: SystemToolError?
}

struct AgentMemoryEntry: Codable, Identifiable {
    var id: String { key }
    let key: String
    let value: AnyCodable
    let category: String?
}

struct AgentCheckpoint: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let description: String
    let branchName: String?
}

struct AgentDiff: Codable, Identifiable {
    var id: String { filePath }
    let filePath: String
    let diff: String
}

struct AgentTimelineStep: Codable, Identifiable {
    let id: String
    let step: String // PLAN, AUDIT, EXECUTE, VERIFY
    let status: String
    let timestamp: Date
}

struct AgentPlanGenerated: Codable {
    let plan: AgentPlan
}

struct AgentPlan: Codable {
    let id: String
    let steps: [AgentPlanStep]
}

struct AgentPlanStep: Codable {
    let id: String
    let title: String
    let index: Int?
}

struct AgentProgressUpdated: Codable {
    let title: String?
    let description: String?
}

struct AgentSessionCompleted: Codable {}

/// Represents a Jules source.
struct AgentSource: Codable, Identifiable {
    let id: String
    let name: String
    let githubRepo: AgentGitHubRepo?
}

struct AgentGitHubRepo: Codable {
    let owner: String
    let repo: String
}

struct AgentSourcesResponse: Codable {
    let sources: [AgentSource]?
}

struct AgentSessionsResponse: Codable {
    let sessions: [AgentSession]?
}

struct AgentActivitiesResponse: Codable {
    let activities: [AgentActivity]?
}
