import Foundation

final class SummarizeMemoryTool: SystemTool {
    let name = "summarize_memory"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool summarize_memory executed successfully")],
            error: nil,
            context: context
        )
    }
}
