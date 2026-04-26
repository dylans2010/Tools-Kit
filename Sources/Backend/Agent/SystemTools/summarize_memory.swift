import Foundation

final class SummarizeMemoryTool: SystemTool {
    let name = "summarize_memory"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
