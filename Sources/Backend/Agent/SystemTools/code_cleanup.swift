import Foundation

final class CodeCleanupTool: SystemTool {
    let name = "code_cleanup"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
