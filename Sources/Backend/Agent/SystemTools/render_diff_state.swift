import Foundation

final class RenderDiffStateTool: SystemTool {
    let name = "render_diff_state"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
