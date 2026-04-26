import Foundation

final class ExecuteScriptTool: SystemTool {
    let name = "execute_script"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool execute_script executed successfully")],
            error: nil,
            context: context
        )
    }
}
