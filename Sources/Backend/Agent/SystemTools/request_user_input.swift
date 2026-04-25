import Foundation

final class RequestUserInputTool: SystemTool {
    let name = "request_user_input"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool request_user_input executed successfully")],
            error: nil,
            context: context
        )
    }
}
