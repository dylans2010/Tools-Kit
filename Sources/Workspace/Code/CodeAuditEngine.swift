import Foundation

/// Analyzes the structure of a GitHub repository for modular extraction.
final class CodeAuditEngine {
    nonisolated(unsafe) static let shared = CodeAuditEngine()

    private let github = GitHubAPIClient.shared

    struct RepoStructure: Codable, Sendable {
        let files: [RepoFile]
    }

    struct RepoFile: Codable, Sendable {
        let name: String
        let path: String
        let type: String // "file" or "dir"
        let size: Int
    }

    func auditRepository(owner: String, repo: String) async throws -> RepoStructure {
        // Recursive fetch of the tree might be needed for full audit,
        // but for alpha we start with top-level and key directories.
        let contents: [RepoFile] = try await github.request(.contents(owner: owner, repo: repo, path: "", ref: nil))

        var allFiles = contents

        // Simple heuristic: if we see "Sources", "lib", or "Classes", dive in
        for item in contents where item.type == "dir" {
            if ["Sources", "lib", "Classes", "Features", "Core"].contains(item.name) {
                let sub: [RepoFile] = try await github.request(.contents(owner: owner, repo: repo, path: item.path, ref: nil))
                allFiles.append(contentsOf: sub)
            }
        }

        return RepoStructure(files: allFiles)
    }
}
