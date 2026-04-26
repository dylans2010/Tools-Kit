import Foundation

final class AbortTaskTool: SystemTool {
    let name = "abort_task"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
