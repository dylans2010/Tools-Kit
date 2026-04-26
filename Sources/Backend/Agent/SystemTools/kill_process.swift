import Foundation

final class KillProcessTool: SystemTool {
    let name = "kill_process"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
