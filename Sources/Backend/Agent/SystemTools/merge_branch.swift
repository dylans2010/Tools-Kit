import Foundation

final class MergeBranchTool: SystemTool {
    let name = "merge_branch"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
