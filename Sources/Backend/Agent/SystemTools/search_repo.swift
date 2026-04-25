import Foundation

final class SearchRepoTool: SystemTool {
    let name = "search_repo"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool search_repo executed successfully")],
            error: nil,
            context: context
        )
    }
}
