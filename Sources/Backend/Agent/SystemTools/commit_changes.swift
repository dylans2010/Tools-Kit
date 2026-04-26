import Foundation

final class CommitChangesTool: SystemTool {
    let name = "commit_changes"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
