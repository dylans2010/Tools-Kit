import Foundation

final class ToolDiscoveryTool: SystemTool {
    let name = "tool_discovery"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
