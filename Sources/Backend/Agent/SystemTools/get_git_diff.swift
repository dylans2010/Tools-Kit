import Foundation

final class GetGitDiffTool: SystemTool {
    let name = "get_git_diff"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
