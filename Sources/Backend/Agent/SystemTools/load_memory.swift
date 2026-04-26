import Foundation

final class LoadMemoryTool: SystemTool {
    let name = "load_memory"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
