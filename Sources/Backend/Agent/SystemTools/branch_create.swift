import Foundation

final class BranchCreateTool: SystemTool {
    let name = "branch_create"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
