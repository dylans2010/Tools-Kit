import Foundation

final class RefactorCodeTool: SystemTool {
    let name = "refactor_code"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
