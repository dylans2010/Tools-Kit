import Foundation

final class RenderDiffStateTool: SystemTool {
    let name = "render_diff_state"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool render_diff_state executed successfully")],
            error: nil,
            context: context
        )
    }
}
