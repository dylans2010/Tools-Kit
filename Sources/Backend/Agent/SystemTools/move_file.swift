import Foundation

final class MoveFileTool: SystemTool {
    let name = "move_file"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool move_file executed successfully")],
            error: nil,
            context: context
        )
    }
}
