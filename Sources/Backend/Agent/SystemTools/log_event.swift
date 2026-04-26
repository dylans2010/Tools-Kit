import Foundation

final class LogEventTool: SystemTool {
    let name = "log_event"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool log_event executed successfully")],
            error: nil,
            context: context
        )
    }
}
