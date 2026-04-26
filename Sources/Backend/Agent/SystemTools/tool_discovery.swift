import Foundation

final class ToolDiscoveryTool: SystemTool {
    let name = "tool_discovery"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        let tools = Array(AgentSystemTools.shared.tools.keys).sorted()
        if name == "tool_discovery" {
            return successResponse(input: input, context: context, output: ["tools": tools, "count": tools.count])
        }
        return successResponse(input: input, context: context, output: ["total_tools": tools.count, "healthy_tools": tools])
    }
}
