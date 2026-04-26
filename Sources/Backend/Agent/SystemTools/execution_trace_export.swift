import Foundation

final class ExecutionTraceExportTool: SystemTool {
    let name = "execution_trace_export"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
