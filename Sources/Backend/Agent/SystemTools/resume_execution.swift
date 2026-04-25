import Foundation

final class ResumeExecutionTool: SystemTool {
    let name = "resume_execution"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        return SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: ["message": AnyCodable("Tool resume_execution executed successfully")],
            error: nil,
            context: context
        )
    }
}
