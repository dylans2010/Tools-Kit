import Foundation

final class RequestUserInputTool: SystemTool {
    let name = "request_user_input"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
