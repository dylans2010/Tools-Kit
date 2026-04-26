import Foundation

final class UpdateTimelineTool: SystemTool {
    let name = "update_timeline"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
