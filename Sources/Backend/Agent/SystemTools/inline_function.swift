import Foundation

final class InlineFunctionTool: SystemTool {
    let name = "inline_function"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool inline_function executed successfully")],
            error: nil,
            context: context
        )
    }
}
