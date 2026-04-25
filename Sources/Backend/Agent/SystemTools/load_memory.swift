import Foundation

final class LoadMemoryTool: SystemTool {
    let name = "load_memory"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool load_memory executed successfully")],
            error: nil,
            context: context
        )
    }
}
