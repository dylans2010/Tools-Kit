import Foundation

final class CodeExplainTool: SystemTool {
    let name = "code_explain"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool code_explain executed successfully")],
            error: nil,
            context: context
        )
    }
}
