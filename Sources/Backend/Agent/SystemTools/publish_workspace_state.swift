import Foundation

final class PublishWorkspaceStateTool: SystemTool {
    let name = "publish_workspace_state"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
