import Foundation

final class MergeBranchTool: SystemTool {
    let name = "merge_branch"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool merge_branch executed successfully")],
            error: nil,
            context: context
        )
    }
}
