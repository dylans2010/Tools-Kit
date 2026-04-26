import Foundation

final class ClearMemoryTool: SystemTool {
    let name = "clear_memory"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
