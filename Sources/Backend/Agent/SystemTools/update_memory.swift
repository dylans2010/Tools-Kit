import Foundation

final class UpdateMemoryTool: SystemTool {
    let name = "update_memory"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
