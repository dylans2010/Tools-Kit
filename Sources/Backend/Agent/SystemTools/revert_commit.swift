import Foundation

final class RevertCommitTool: SystemTool {
    let name = "revert_commit"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool revert_commit executed successfully")],
            error: nil,
            context: context
        )
    }
}
