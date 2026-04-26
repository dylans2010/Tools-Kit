import Foundation

final class WorkspaceSnapshotTool: SystemTool {
    let name = "workspace_snapshot"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
