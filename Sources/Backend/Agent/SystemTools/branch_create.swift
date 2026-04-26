import Foundation

final class BranchCreateTool: SystemTool {
    let name = "branch_create"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool branch_create executed successfully")],
            error: nil,
            context: context
        )
    }
}
