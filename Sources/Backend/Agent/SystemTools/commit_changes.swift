import Foundation

final class CommitChangesTool: SystemTool {
    let name = "commit_changes"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool commit_changes executed successfully")],
            error: nil,
            context: context
        )
    }
}
