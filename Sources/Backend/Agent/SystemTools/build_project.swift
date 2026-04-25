import Foundation

final class BuildProjectTool: SystemTool {
    let name = "build_project"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool build_project executed successfully")],
            error: nil,
            context: context
        )
    }
}
