import Foundation

final class RestoreCheckpointTool: SystemTool {
    let name = "restore_checkpoint"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
