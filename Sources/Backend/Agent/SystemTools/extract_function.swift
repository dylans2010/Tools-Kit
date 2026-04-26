import Foundation

final class ExtractFunctionTool: SystemTool {
    let name = "extract_function"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool extract_function executed successfully")],
            error: nil,
            context: context
        )
    }
}
