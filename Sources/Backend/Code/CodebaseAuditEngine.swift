import Foundation

final class CodebaseAuditEngine {
    static let shared = CodebaseAuditEngine()

    struct RepoStructure: Codable {
        let files: [RepoFile]
    }

    struct RepoFile: Codable {
        let name: String
        let path: String
        let type: String
        let size: Int
    }

    func auditRepository(owner: String, repo: String) async throws -> RepoStructure {
        return RepoStructure(files: [])
    }
}
