import Foundation

final class GetGitDiffTool: SystemTool {
    let name = "get_git_diff"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool get_git_diff executed successfully")],
            error: nil,
            context: context
        )
    }
}
