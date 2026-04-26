import Foundation

final class GenerateDiffTool: SystemTool {
    let name = "generate_diff"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool generate_diff executed successfully")],
            error: nil,
            context: context
        )
    }
}
