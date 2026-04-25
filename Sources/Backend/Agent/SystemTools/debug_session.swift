import Foundation

final class DebugSessionTool: SystemTool {
    let name = "debug_session"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool debug_session executed successfully")],
            error: nil,
            context: context
        )
    }
}
