import Foundation

final class LintCodeTool: SystemTool {
    let name = "lint_code"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
