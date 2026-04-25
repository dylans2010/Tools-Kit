import Foundation

final class AbortTaskTool: SystemTool {
    let name = "abort_task"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool abort_task executed successfully")],
            error: nil,
            context: context
        )
    }
}
