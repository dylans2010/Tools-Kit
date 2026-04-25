import Foundation

final class RunCommandTool: SystemTool {
    let name = "run_command"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool run_command executed successfully")],
            error: nil,
            context: context
        )
    }
}
