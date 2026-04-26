import Foundation

final class InlineFunctionTool: SystemTool {
    let name = "inline_function"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
