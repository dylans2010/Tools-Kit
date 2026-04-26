import Foundation

final class ToolHealthCheckTool: SystemTool {
    let name = "tool_health_check"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
