import Foundation

final class ReadFileTool: SystemTool {
    let name = "read_file"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool read_file executed successfully")],
            error: nil,
            context: context
        )
    }
}
