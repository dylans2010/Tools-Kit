import Foundation

final class ExecuteScriptTool: SystemTool {
    let name = "execute_script"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
