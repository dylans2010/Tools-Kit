import Foundation

final class CodeExplainTool: SystemTool {
    let name = "code_explain"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
