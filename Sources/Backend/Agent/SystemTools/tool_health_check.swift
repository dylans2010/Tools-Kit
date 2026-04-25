import Foundation

final class ToolHealthCheckTool: SystemTool {
    let name = "tool_health_check"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool tool_health_check executed successfully")],
            error: nil,
            context: context
        )
    }
}
