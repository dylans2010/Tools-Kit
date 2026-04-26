import Foundation

final class CreateCheckpointTool: SystemTool {
    let name = "create_checkpoint"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
