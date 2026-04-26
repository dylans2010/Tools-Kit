import Foundation

final class PauseExecutionTool: SystemTool {
    let name = "pause_execution"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
