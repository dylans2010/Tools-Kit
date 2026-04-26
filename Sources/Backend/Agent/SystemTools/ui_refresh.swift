import Foundation

final class UiRefreshTool: SystemTool {
    let name = "ui_refresh"

    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse {
        await SystemToolShellExecutor.execute(tool: name, input: input, context: context)
    }
}
