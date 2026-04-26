import Foundation

final class AppendFileTool: SystemTool {
    let name = "append_file"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
