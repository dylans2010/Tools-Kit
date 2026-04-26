import Foundation

final class SaveMemoryTool: SystemTool {
    let name = "save_memory"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
