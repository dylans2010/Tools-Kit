import Foundation

final class StreamExecutionTool: SystemTool {
    let name = "stream_execution"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool stream_execution executed successfully")],
            error: nil,
            context: context
        )
    }
}
