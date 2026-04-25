import Foundation

final class LintCodeTool: SystemTool {
    let name = "lint_code"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool lint_code executed successfully")],
            error: nil,
            context: context
        )
    }
}
