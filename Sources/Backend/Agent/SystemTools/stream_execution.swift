import Foundation

final class StreamExecutionTool: SystemTool {
    let name = "stream_execution"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
