import Foundation

final class KillProcessTool: SystemTool {
    let name = "kill_process"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool kill_process executed successfully")],
            error: nil,
            context: context
        )
    }
}
