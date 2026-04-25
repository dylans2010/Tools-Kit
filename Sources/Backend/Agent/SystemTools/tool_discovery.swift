import Foundation

final class ToolDiscoveryTool: SystemTool {
    let name = "tool_discovery"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool tool_discovery executed successfully")],
            error: nil,
            context: context
        )
    }
}
