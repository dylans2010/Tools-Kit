import Foundation

/// Represents a GitHub repository.
struct GitHubRepository: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let owner: GitHubUser
    let htmlUrl: String
    let stargazersCount: Int
    let forksCount: Int
    let watchersCount: Int
    let defaultBranch: String
    let language: String?
    let `private`: Bool
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, owner
        case fullName = "full_name"
        case htmlUrl = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case watchersCount = "watchers_count"
        case defaultBranch = "default_branch"
        case language
        case `private`
        case updatedAt = "updated_at"
    }
}

/// Represents a GitHub user.
struct GitHubUser: Codable, Identifiable, Hashable {
    let id: Int
    let login: String
    let avatarUrl: String
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case id, login
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
    }
}

/// Represents a Git branch.
struct GitHubBranch: Codable, Hashable {
    let name: String
    let commit: GitHubCommitInfo
    let `protected`: Bool
}

struct GitHubCommitInfo: Codable, Hashable {
    let sha: String
    let url: String
}

/// Represents a Git commit in history.
struct GitHubCommit: Codable, Identifiable, Hashable {
    var id: String { sha }
    let sha: String
    let commit: GitHubCommitDetail
    let author: GitHubUser?
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case sha, commit, author
        case htmlUrl = "html_url"
    }
}

struct GitHubCommitDetail: Codable, Hashable {
    let author: GitHubCommitAuthor
    let message: String
}

struct GitHubCommitAuthor: Codable, Hashable {
    let name: String
    let email: String
    let date: Date
}

/// Represents a Pull Request.
struct GitHubPullRequest: Codable, Identifiable, Hashable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: String
    let user: GitHubUser
    let htmlUrl: String
    let createdAt: Date
    let head: GitHubPRBranch
    let base: GitHubPRBranch
    let draft: Bool?
    let mergedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, number, title, body, state, user, draft
        case htmlUrl = "html_url"
        case createdAt = "created_at"
        case head, base
        case mergedAt = "merged_at"
    }
}

struct GitHubPRBranch: Codable, Hashable {
    let label: String
    let ref: String
    let sha: String
    let repo: GitHubRepository?
}

/// Represents file/directory content in a repo.
struct GitHubContent: Codable, Hashable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let type: String // "file", "dir", "symlink", "submodule"
    let content: String? // Base64 encoded, only for files
    let encoding: String?
    let downloadUrl: String?

    enum CodingKeys: String, CodingKey {
        case name, path, sha, size, type, content, encoding
        case downloadUrl = "download_url"
    }
}

/// Represents comparison between two commits/branches.
struct GitHubComparison: Codable {
    let status: String
    let aheadBy: Int
    let behindBy: Int
    let commits: [GitHubCommit]
    let files: [GitHubFileDiff]

    enum CodingKeys: String, CodingKey {
        case status, commits, files
        case aheadBy = "ahead_by"
        case behindBy = "behind_by"
    }
}

struct GitHubFileDiff: Codable, Hashable {
    let sha: String
    let filename: String
    let status: String // "added", "removed", "modified", "renamed", "copied"
    let additions: Int
    let deletions: Int
    let changes: Int
    let patch: String?
}
