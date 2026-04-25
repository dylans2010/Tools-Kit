import Foundation

/// Represents a Jules session.
struct AgentSession: Codable, Identifiable {
    let id: String
    let name: String
    let title: String?
    let prompt: String
    let sourceContext: AgentSourceContext
    let outputs: [AgentOutput]?

    enum CodingKeys: String, CodingKey {
        case id, name, title, prompt, outputs
        case sourceContext = "sourceContext"
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
    let pullRequest: AgentPullRequest?
}

struct AgentPullRequest: Codable {
    let url: String
    let title: String?
    let description: String?
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

    enum CodingKeys: String, CodingKey {
        case id, name, createTime, originator
        case planGenerated, progressUpdated, sessionCompleted
    }
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
