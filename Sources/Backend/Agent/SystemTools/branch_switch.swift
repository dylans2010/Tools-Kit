import Foundation

final class BranchSwitchTool: SystemTool {
    let name = "branch_switch"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
