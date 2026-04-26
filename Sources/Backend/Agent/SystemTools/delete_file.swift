import Foundation

final class DeleteFileTool: SystemTool {
    let name = "delete_file"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
