import Foundation

final class FormatCodeTool: SystemTool {
    let name = "format_code"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool format_code executed successfully")],
            error: nil,
            context: context
        )
    }
}
