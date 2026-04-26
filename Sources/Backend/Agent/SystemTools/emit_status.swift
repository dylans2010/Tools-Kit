import Foundation

final class EmitStatusTool: SystemTool {
    let name = "emit_status"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
