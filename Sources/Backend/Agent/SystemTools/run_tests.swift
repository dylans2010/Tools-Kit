import Foundation

final class RunTestsTool: SystemTool {
    let name = "run_tests"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool run_tests executed successfully")],
            error: nil,
            context: context
        )
    }
}
