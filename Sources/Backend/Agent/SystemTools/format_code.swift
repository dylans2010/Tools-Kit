import Foundation

final class FormatCodeTool: SystemTool {
    let name = "format_code"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
