import Foundation

final class DebugSessionTool: SystemTool {
    let name = "debug_session"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
