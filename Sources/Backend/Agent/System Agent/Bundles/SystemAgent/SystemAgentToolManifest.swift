import Foundation

struct SystemAgentToolManifest: Sendable {
    static let tools = [
        "build_project",
        "run_tests",
        "commit_changes",
        "branch_create"
    ]
}
