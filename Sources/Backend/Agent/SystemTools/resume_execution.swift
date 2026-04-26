import Foundation

final class ResumeExecutionTool: SystemTool {
    let name = "resume_execution"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
