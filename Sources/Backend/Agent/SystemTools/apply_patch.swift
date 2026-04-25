import Foundation

final class ApplyPatchTool: SystemTool {
    let name = "apply_patch"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool apply_patch executed successfully")],
            error: nil,
            context: context
        )
    }
}
